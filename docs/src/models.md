# Models

## Types of models

```@autodocs
Modules = [EventStudies.Models]
Filter = x -> typeof(x) === DataType
```

## Model API

To define a new model, you need to create a `struct MyModel <: EventStudies.Models.AbstractModel`, whose contents can be arbitrary.  

Then, you have to implement `StatsBase.fit!(model::MyModel, data::TSFrame)::MyModel`, which should mutate the model to store the coefficients (you can do this in an immutable struct by making one of the fields a mutable type like a `Vector`).

Finally, you have to implement `StatsBase.predict(model::MyModel, data::TSFrame)::TSFrame` which runs the model and returns the result as a TSFrame.  Column names should not be changed and `data` should not be mutated.

Optionally, you can also implement `Models.check_window(model::MyModel, window)::Bool`, which checks whether the given window exists in your model.

```@docs
EventStudies.StatsBase.fit!
EventStudies.StatsBase.predict
```