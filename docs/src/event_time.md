# Event time

Event time is the fundamental concept of the event study.  When an event study is performed, windows around each event are extracted, and re-indexed to an "event time" where the event occurs at ``t=0``.

`EventStudies.jl` offers a simple interface to perform direct conversion of a timeseries and a set of events to event time, with the [`physical_to_event_time`](@ref) function:

```@docs
EventStudies.physical_to_event_time
```

## Event codes

Each event has an associated event time.  If the time is not viable to study (outside the index of the input data), 
or there is some issue with either the data or the model, then the event will be ignored.

Ignored events have an event code which describes _why_ they were ignored; successful events have the code [`EventStudies.Success`](@ref).

```@autodocs
Modules = [EventStudies]
Filter = x -> typeof(x) === DataType && x <: EventStudies.EventStatus
```