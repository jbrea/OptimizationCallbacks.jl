# OptimizationCallbacks.jl

<!-- Tidyverse lifecycle badges, see https://www.tidyverse.org/lifecycle/ Uncomment or delete as needed. -->
<!--
![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)--->
![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)<!--
![lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![build](https://github.com/jbrea/OptimizationCallbacks.jl/workflows/CI/badge.svg)](https://github.com/jbrea/OptimizationCallbacks.jl/actions?query=workflow%3ACI)
<!-- travis-ci.com badge, uncomment or delete as needed, depending on whether you are using that service. -->
<!-- [![Build Status](https://travis-ci.com/jbrea/OptimizationCallbacks.jl.svg?branch=master)](https://travis-ci.com/jbrea/OptimizationCallbacks.jl) -->
<!-- NOTE: Codecov.io badge now depends on the token, copy from their site after setting up -->
<!-- Documentation -- uncomment or delete as needed -->
<!--
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://jbrea.github.io/OptimizationCallbacks.jl/stable) --->
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://jbrea.github.io/OptimizationCallbacks.jl/dev)
<!-- Aqua badge, see test/runtests.jl -->
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


This package contains a bunch of callable objects that can be useful as callbacks in optimization, such as progress logging (`LogProgress`), check point saving (`CheckPointSaver`), or evaluations on other functions, e.g. for tracking validation losses (`Evaluator`). These callbacks can be triggered with different mechanisms, either based on iteration step (`IterationTrigger`), on time (`TimeTrigger`), or on special events, e.g. at the end of optimization (`EventTrigger`). The package is tested with the popular [Optimization.jl](https://docs.sciml.ai/Optimization) package, but it does not depend on it and can also be used in custom optimization procedures, or with other packages.

```julia
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

More examples can be found in the [documentation](https://jbrea.github.io/OptimizationCallbacks.jl/dev).
