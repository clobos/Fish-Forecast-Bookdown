## ----setup, include=FALSE, message=FALSE---------------------------------
options(htmltools.dir.version = FALSE, servr.daemon = TRUE)
library(huxtable)

## ----load_data_exp_smoothing, echo=FALSE---------------------------------
load("landings.RData")
landings$log.metric.tons = log(landings$metric.tons)
landings = subset(landings, Year <= 1989)
landings = subset(landings, Species %in% c("Anchovy","Sardine"))
library(ggplot2)

