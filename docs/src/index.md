# OptimizationCallbacks

This package contains a bunch of callable objects that can be useful as callbacks in optimization, such as progress logging (`LogProgress`), check point saving (`CheckPointSaver`), or evaluations on other functions, e.g. for tracking validation losses (`Evaluator`). These callbacks can be triggered with different mechanisms, either based on iteration step (`IterationTrigger`), on time (`TimeTrigger`), or on special events, e.g. at the end of optimization (`EventTrigger`). The package is tested with the popular [Optimization.jl](https://docs.sciml.ai/Optimization) package, but it does not depend on it and can also be used in custom optimization procedures, or with other packages.

```@autodocs
Modules = [OptimizationCallbacks]
```
