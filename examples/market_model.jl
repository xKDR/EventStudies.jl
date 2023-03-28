# # Using a market model with EventStudies.jl

# We load the following packages:
using TSFrames, DataFrames, CSV, MarketData
using Dates
using EventStudies
using CairoMakie # for plotting

# We load the NIFTY index from MarketData.jl:
nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)
dropmissing!(nifty.coredata)

# We load the following stocks from MarketData.jl:

nifty_id_table = CSV.read("/Users/anshul/Downloads/ind_nifty50list.csv", DataFrame)

nifty_ticker_tsframes = TSFrame.(MarketData.yahoo.(nifty_id_table.Symbol .* ".NS"))
old_ntt = deepcopy.(nifty_ticker_tsframes)
nifty_ticker_tsframes = deepcopy(old_ntt)

# We loop through the TSFrames and select the AdjClose column for each stock, and rename it to the stock's ticker symbol.
for (name, ts) in zip(nifty_id_table.Symbol, nifty_ticker_tsframes) 
    select!(ts.coredata, :Index, :AdjClose => (x -> max.(0.0, x)) => Symbol(name))
end

dropmissing!.(getproperty.(nifty_ticker_tsframes, :coredata))

# Finally, we convert the prices to returns:
nifty_ticker_returns_tsframe = TSFrames.join(levels_to_returns.(nifty_ticker_tsframes)...; jointype = :JoinAll)
nifty_returns = levels_to_returns(nifty)

# We create a MarketModel object, which will be used to apply the market model to the stock returns:
market_model = MarketModel(nifty_returns)
data = nifty_ticker_returns_tsframe[:, [:RELIANCE]]
fit!(market_model, data)

# Let's process our data for plotting, since Makie doesn't support "time axes" yet.
nifty_plottable_data = TSFrames.subset(nifty_returns, Date(2015, 1, 1), Dates.today())
reliance_plottable_data = TSFrames.subset(nifty_ticker_returns_tsframe[:, [:RELIANCE]], Date(2015, 1, 1), Dates.today())
ret = EventStudies.Models.predict(market_model, reliance_plottable_data)
reliance_decor_plottable_data = TSFrames.subset(ret, Date(2015, 1, 1), Dates.today())
dropmissing!(reliance_decor_plottable_data.coredata)

f, a, p = lines(Dates.value.(index(reliance_plottable_data) .- Date(2015, 1, 1)), (reliance_plottable_data |> EventStudies.remap_cumsum).RELIANCE; label = "RELIANCE")
p2 = lines!(a, Dates.value.(index(reliance_decor_plottable_data) .- Date(2015, 1, 1)), (reliance_decor_plottable_data |> EventStudies.remap_cumsum).RELIANCE; label = "Reliance after market model")
p3 = lines!(a, Dates.value.(index(nifty_plottable_data) .- Date(2015, 1, 1)), (nifty_plottable_data |> EventStudies.remap_cumsum).var"NIFTY"; label = "NIFTY index")
f
autolimits!(a)
# xlims!(a, nothing, nothing)
f
axislegend(a, position = :rb)
a.title = "Market model on NIFTY index"
a.xlabel = "Days since 1/1/2015"
a.ylabel = "Cumulative returns (%)"
f

# We perform an eventstudy while passing this market model:

using BenchmarkTools
event_times = rand(1000:2000, 1000)
event_cols = rand(names(nifty_ticker_returns_tsframe), 1000)

@benchmark eventtime_return_ts, success_codes = EventStudies.eventstudy(
    nifty_ticker_returns_tsframe,
    Symbol.(event_cols) .=> index(nifty_returns)[event_times],
    20,
    MarketModel(nifty_returns),
    verbose = false
)

# Single threaded performance

# ───────────────────────────────────────────────────────────────────────────────────────
# Time                    Allocations      
# ───────────────────────   ────────────────────────
# Tot / % measured:               22.5s /  58.9%           36.0GiB / 100.0%    

# Section                      ncalls     time    %tot     avg     alloc    %tot      avg
# ───────────────────────────────────────────────────────────────────────────────────────
# Applying models                  28    13.0s   97.6%   463ms   35.7GiB   99.1%  1.28GiB
# Physical to event time           28    197ms    1.5%  7.02ms    245MiB    0.7%  8.74MiB
# Constructing return object       28    116ms    0.9%  4.15ms   76.1MiB    0.2%  2.72MiB
# ───────────────────────────────────────────────────────────────────────────────────────

# BenchmarkTools.Trial: 11 samples with 1 evaluation.
#  Range (min … max):  459.094 ms … 481.245 ms  ┊ GC (min … max): 18.38% … 20.15%
#  Time  (median):     473.502 ms               ┊ GC (median):    19.75%
#  Time  (mean ± σ):   472.228 ms ±   7.021 ms  ┊ GC (mean ± σ):  19.67% ±  0.55%

#   █                █   █ █      █        █ █        █  █    █ █  
#   █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁█▁█▁▁▁▁▁▁█▁▁▁▁▁▁▁▁█▁█▁▁▁▁▁▁▁▁█▁▁█▁▁▁▁█▁█ ▁
#   459 ms           Histogram: frequency by time          481 ms <

#  Memory estimate: 1.29 GiB, allocs estimate: 973311.

# Multithreaded performance

# ───────────────────────────────────────────────────────────────────────────────────────
# Time                    Allocations      
# ───────────────────────   ────────────────────────
# Tot / % measured:               69.6s /  17.2%           85.2GiB /  99.7%    

# Section                      ncalls     time    %tot     avg     alloc    %tot      avg
# ───────────────────────────────────────────────────────────────────────────────────────
# Applying models                  66    11.2s   94.0%   170ms   84.2GiB   99.1%  1.28GiB
# Physical to event time           66    437ms    3.7%  6.62ms    577MiB    0.7%  8.74MiB
# Constructing return object       66    284ms    2.4%  4.31ms    179MiB    0.2%  2.72MiB
# ───────────────────────────────────────────────────────────────────────────────────────

# BenchmarkTools.Trial: 31 samples with 1 evaluation.
# Range (min … max):  112.229 ms … 257.885 ms  ┊ GC (min … max): 23.70% … 21.22%
# Time  (median):     153.552 ms               ┊ GC (median):    24.53%
# Time  (mean ± σ):   162.495 ms ±  35.347 ms  ┊ GC (mean ± σ):  24.12% ±  2.10%

# ▂█                        ▅                             
# ▅▁▁▁▁▁▁███▁▁▁▁▅▅███▅▅▁▁▁▁▁▁▁▁▁▅▁▁██▁▅▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▅▅ ▁
# 112 ms           Histogram: frequency by time          258 ms <

# Memory estimate: 1.29 GiB, allocs estimate: 992782.