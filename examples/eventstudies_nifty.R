# eventstudies for NIFTY close and USD/INR close with the events being us fed rate hikes 
# Author: Sayan Dasgupta
# Loading required librarie
library(zoo)
library(tidyverse)
library(devtools)
library(eventstudies)
library(lubridate)
library(stringr)
library(dplyr)
library(tidyr)
library(RMySQL)
library(data.table)
library(latex2exp)
library(ggplot2)
library(fredr)

### Reading the nifty and usd/inr data and creating two zoo objects
nifty <- as.data.frame(read.csv("../DATA/nifty_data.csv",check.names=FALSE))
nifty <- nifty %>% filter(Index >= "2007-01-01" & Index <= "2023-01-01")
nifty1 <- subset(nifty,select = c(Index,Close))
colnames(nifty1)[1] ="date"
colnames(nifty1)[2] ="nifty_close"
nifty_zoo <- read.zoo(nifty1,drop = FALSE)
usd_inr <- as.data.frame(read.csv("../DATA/usd_inr_data.csv",check.names=FALSE))
usd_inr <- usd_inr %>% filter(Index >= "2007-01-01" & Index <= "2023-01-01")
usd_inr1 <- subset(usd_inr,select = c(Index,Close))
colnames(usd_inr1)[1] ="date"
colnames(usd_inr1)[2] ="usd_inr"
usd_inr_zoo <- read.zoo(usd_inr1,drop = FALSE)

### Retrieve US Federal funds effective rate data
fred_rate <- fredr(
  series_id = "FEDFUNDS",
  observation_start = as.Date("2007-01-01"),
  observation_end = as.Date("2023-01-01")
)

fred_rate <- as.data.frame(fred_rate)
# Calculate difference between consecutive values
diffs <- diff(fred_rate$value)
positive_diffs <- which(diffs > 0)
positive_dates <- fred_rate$date[positive_diffs + 1]
df <- data.frame(name = "nifty_close", when = positive_dates)
df$name = "nifty_close"
df_usd <- data.frame(name = "nifty_close", when = positive_dates)
df_usd$name = "usd_inr"
## Doing the NIFTY Event studies 
es_us_nifty <- eventstudy(firm.returns = nifty_zoo,
                 event.list = df,
                 event.window = 7,
                 type = "None",
                 to.remap = FALSE,
                 is.levels = TRUE, 
                 inference = TRUE,
                 inference.strategy = "bootstrap")

pdf("eventstudy_nifty_us_fed_rate_hikes.pdf")
plot(es_us_nifty)
dev.off()

## Doing the USD/INR Event studies 
es_usd_inr <- eventstudy(firm.returns = usd_inr_zoo,
                 event.list = df_usd,
                 event.window = 7,
                 type = "None",
                 to.remap = FALSE,
                 is.levels = TRUE, 
                 inference = TRUE,
                 inference.strategy = "bootstrap")

pdf("eventstudy_usd_inr_value_us_fed_rate_hikes.pdf")
plot(es_usd_inr)
dev.off()
#


