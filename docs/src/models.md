# Models

## Types of models

```@autodocs
Modules = [EventStudies]
Filter = x -> typeof(x) === DataType && x <: EventStudies.AbstractEventStudyModel
```

## Model API

To define a new model, you need to create a `struct MyModel <: EventStudies.AbstractEventStudyModel`, whose contents can be arbitrary.  Then, you have to implement `EventStudies.apply_model(model::MyModel, data::TSFrame)`, which must return a Tuple of `(::TSFrame, ::EventStudies.EventStatus)`.