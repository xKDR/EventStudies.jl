## Possible API

```julia
eventtime_return_ts, success_codes = eventstudy(
    nifty_ticker_returns_tsframe,
    market_model,
    eventtimes = Dates.Date(2019, 5, 23),
    eventwindow = -5:5,
    strict = true,
    verbose = true,
)
```