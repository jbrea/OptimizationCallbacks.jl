"""
Callbacks for [Optimization.jl](https://docs.sciml.ai/Optimization)
"""
module OptimizationCallbacks

using ConcreteStructs
using Printf
using JLD2

export Callback, TimeTrigger, IterationTrigger, EventTrigger, LogProgress, CheckPointSaver, Evaluator

"""
    Callback(trigger, function; t = 0, extra = nothing, stop = (_, _, _, _) -> false)

    Callback((trigger1, trigger2, ...), function)

See triggers [`IterationTrigger`](@ref), [`TimeTrigger`](@ref), [`EventTrigger`](@ref).
For callback functions see [`LogProgress`](@ref), [`CheckPointSaver`](@ref).

The callback `function` has arguments `Optimization.OptimizationState, value, t, extra`.

### Example

```jldoctest
julia> using Optimization

julia> using OptimizationCallbacks

julia> import ForwardDiff

julia> function rosenbrock(x, p)
           (p[1] - x[1])^2 + p[2] * (x[2] - x[1]^2)^2
       end
rosenbrock (generic function with 1 method)

julia> optf = OptimizationFunction(rosenbrock, AutoForwardDiff());

julia> prob = OptimizationProblem(optf, [0., 0.], [1., 100.]);

julia> callback = Callback(IterationTrigger(5), LogProgress());

julia> sol = solve(prob, Optimization.LBFGS(); callback)
 eval   | current     | lowest      | highest
_________________________________________________
      5 |    0.460215 |    0.460215 |    0.460215
     10 |    0.162607 |    0.162607 |    0.460215
     15 |   0.0257404 |   0.0257404 |    0.460215
     20 | 0.000911646 | 0.000911646 |    0.460215
     25 | 1.04339e-13 | 1.04339e-13 |    0.460215
retcode: Success
u: 2-element Vector{Float64}:
 0.9999997057368228
 0.999999398151528

```
"""
@concrete mutable struct Callback
    trigger
    func
    t
    extra
    stop
end
function Callback(trigger, func; t = 0, extra = nothing, stop = (_, _, _, _) -> false)
    Callback(trigger, func, t, extra, stop)
end
function (cb::Callback)(state, value)
    cb.t += 1
    if cb.trigger(state, value, cb.t, cb.extra)
        cb.func(state, value, cb.t, cb.extra)
    end
    cb.stop(state, value, cb.t, cb.extra)
end
function (cb::Callback{<:Tuple})(state, value)
    cb.t += 1
    if any(map(f -> f(state, value, cb.t, cb.extra), cb.trigger))
        cb.func(state, value, cb.t, cb.extra)
    end
    cb.stop(state, value, cb.t, cb.extra)
end


"""
    reset!(callback)

Resets internal states, like iteration counters, in a [`Callback`](@ref).

### Example
```jldoctest
julia> using Optimization

julia> using OptimizationCallbacks

julia> callback = Callback(IterationTrigger(5), LogProgress());

julia> for _ in 1:6
           callback(Optimization.OptimizationState(), 17.); # arbitrary calls to callback
       end
 eval   | current     | lowest      | highest
_________________________________________________
      5 |          17 |          17 |          17

julia> callback.t
6

julia> callback.func.lowest
17.0

julia> OptimizationCallbacks.reset!(callback);

julia> callback.t
0

julia> callback.func.lowest
Inf

```
"""
function reset!(cb::Callback)
    reset!(cb.trigger)
    reset!(cb.func)
    cb.t = 0
    cb
end
reset!(_) = nothing
reset!(t::Tuple) = reset!.(t)


"""
    TimeTrigger(Δt)

Triggers every `Δt` seconds.

### Example

```jldoctest
julia> using Optimization

julia> using OptimizationCallbacks

julia> import ForwardDiff

julia> function rosenbrock(x, p)
           sleep(.1)
           (p[1] - x[1])^2 + p[2] * (x[2] - x[1]^2)^2
       end
rosenbrock (generic function with 1 method)

julia> optf = OptimizationFunction(rosenbrock, AutoForwardDiff());

julia> prob = OptimizationProblem(optf, [0., 0.], [1., 100.]);

julia> callback = Callback(TimeTrigger(2.0), (_,_,_,_) -> @info("Hi"));

julia> sol = solve(prob, Optimization.LBFGS(); callback)
[ Info: Hi
[ Info: Hi
retcode: Success
u: 2-element Vector{Float64}:
 0.9999997057368228
 0.999999398151528

```
"""
@concrete mutable struct TimeTrigger
    t0
    Δt
end
TimeTrigger(Δt) = TimeTrigger(-Inf, Δt)
function reset!(t::TimeTrigger)
    t.t0 = -Inf
    t
end
function (t::TimeTrigger)(_, _, _, _)
    if t.t0 === -Inf
        t.t0 = time()
    end
    if time() - t.t0 > t.Δt
        t.t0 = time()
        return true
    else
        return false
    end
end
"""
    IterationTrigger(Δi)

Triggers every `Δi` iterations. See [`Callback`](@ref) for an example.

"""
@concrete mutable struct IterationTrigger
    i0
    Δi
end
IterationTrigger(Δi) = IterationTrigger(0, Δi)
function reset!(t::IterationTrigger)
    t.i0 = 0
    t
end
function (cb::IterationTrigger)(_, _, t, _)
    if t - cb.i0 ≥ cb.Δi
        cb.i0 = t
        return true
    else
        return false
    end
end
"""
    EventTrigger(events)

Triggers at given events using the [`trigger!`](@ref) function.

### Example
```jldoctest
julia> using OptimizationCallbacks

julia> callback = Callback(EventTrigger((:start, :end)), (_, value,_ ,_) -> @info( "Current value: " * string(value)));

julia> begin
           @info "Start."
           OptimizationCallbacks.trigger!(callback, :start)
           callback(nothing, 10.)
           callback(nothing, 9.)
           callback(nothing, 7.)
           OptimizationCallbacks.trigger!(callback, :end)
           callback(nothing, 6.)
       end;
[ Info: Start.
[ Info: Current value: 10.0
[ Info: Current value: 6.0
```
"""
@concrete mutable struct EventTrigger
    events
    triggered
end
EventTrigger(events) = EventTrigger(events, false)
function (t::EventTrigger)(_, _, _, _)
    if t.triggered
        t.triggered = false
        return true
    else
        return false
    end
end
"""
    trigger!(callback, event)

Trigger [`EventTrigger`](@ref) with `event`. For example see [`EventTrigger`](@ref) or [`CheckPointSaver`](@ref).
"""
trigger!(::Any, ::Any) = nothing
trigger!(cb::Callback, event) = trigger!(cb.trigger, event)
trigger!(cb::Callback{<:Tuple}, event) = trigger!.(cb.trigger, Ref(event))
trigger!(t::EventTrigger, event) = t.triggered = event ∈ t.events

"""
    CheckPointSaver(filename; overwrite = false)

Saves checkpoints as `JLD2` files.

### Examples
```jldoctest
julia> using Optimization

julia> using OptimizationCallbacks

julia> import ForwardDiff

julia> function rosenbrock(x, p)
           (p[1] - x[1])^2 + p[2] * (x[2] - x[1]^2)^2
       end;

julia> optf = OptimizationFunction(rosenbrock, AutoForwardDiff());

julia> prob = OptimizationProblem(optf, [0., 0.], [1., 100.]);

julia> filename = tempname() * ".jld2";

julia> callback = Callback((IterationTrigger(5), EventTrigger((:end,))),
                           CheckPointSaver(filename));

julia> sol = solve(prob, Optimization.LBFGS(); callback);

julia> OptimizationCallbacks.trigger!(callback, :end);

julia> callback(Optimization.OptimizationState(u = sol.u, objective = sol.objective),
                sol.objective);

julia> using JLD2

julia> checkpoint_dict = load(filename);

julia> checkpoint_dict["15"].u
2-element Vector{Float64}:
 0.8834203727171949
 0.7694090396265355

```
"""
struct CheckPointSaver{T}
    filename::String
    transform::T
    function CheckPointSaver(filename; transform = identity, overwrite = false)
        if isfile(filename)
            if overwrite
                rm(filename)
            else
                error("File $filename exists. Use `CheckPointSaver(filename, overwrite = true)` to overwrite")
            end
        end
        new{typeof(transform)}(filename, transform)
    end
end
function (cp::CheckPointSaver)(state, _, t, _)
    jldopen(cp.filename, "a+") do file
        file[string(t)] = cp.transform(state)
    end
end
"""
    LogProgress()

See [`Callback`](@ref) for an example.
"""
mutable struct LogProgress
    i::Int
    lowest::Float64
    highest::Float64
end
LogProgress() = LogProgress(0, Inf, -Inf)
function reset!(cb::LogProgress)
    cb.lowest = Inf
    cb.highest = -Inf
    cb.i = 0
    cb
end
function (cb::LogProgress)(state, value, t, _)
    if cb.i % 50 == 0
        println(" eval   | current     | lowest      | highest     ")
        println("_"^49)
    end
    cb.i += 1
    if value ≤ cb.lowest
        cb.lowest = value
    end
    if value ≥ cb.highest
        cb.highest = value
    end
    @printf "%7i | %11.6g | %11.6g | %11.6g\n" t value cb.lowest cb.highest
end

"""
    Evaluator(f; T = Float64, label = :evaluation)

Evaluate function `f` on `state` and store it in `evaluations`.

### Example

```jldoctest
julia> using Optimization

julia> using OptimizationCallbacks

julia> import ForwardDiff

julia> function rosenbrock(x, p)
           (p[1] - x[1])^2 + p[2] * (x[2] - x[1]^2)^2
       end
rosenbrock (generic function with 1 method)

julia> optf = OptimizationFunction(rosenbrock, AutoForwardDiff());

julia> prob = OptimizationProblem(optf, [0., 0.], [1., 100.]);

julia> callback = Callback(IterationTrigger(5), Evaluator(x -> rosenbrock(x.u, [1., 90.])));

julia> sol = solve(prob, Optimization.LBFGS(); callback);

julia> callback.func.evaluations
5-element Vector{Float64}:
 0.45989873460740843
 0.16216539624081874
 0.024525435426304077
 0.0009100921964470193
 1.0256411872737028e-13
```
"""
struct Evaluator{E,F}
    label::Symbol
    evaluations::E
    f::F
end
function Evaluator(f; T = Float64, label = :evaluation)
    Evaluator{Vector{T},typeof(f)}(label, T[], f)
end
function (ev::Evaluator)(state, _, _, _)
    push!(ev.evaluations, ev.f(state))
end


end # module
