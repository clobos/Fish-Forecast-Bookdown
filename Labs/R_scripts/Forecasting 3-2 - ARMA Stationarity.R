## ----setup, include=FALSE, message=FALSE---------------------------------
options(htmltools.dir.version = FALSE, servr.daemon = TRUE)
library(huxtable)

## ----load_data, message=FALSE, warning=FALSE, echo=FALSE-----------------
load("landings.RData")
landings$log.metric.tons = log(landings$metric.tons)
landings = subset(landings, Year <= 1989)
anchovy = subset(landings, Species=="Anchovy")$log.metric.tons
sardine = subset(landings, Species=="Sardine")$log.metric.tons

library(ggplot2)
library(gridExtra)
library(reshape2)
library(tseries)
library(urca)

## ----eval=FALSE, echo=FALSE----------------------------------------------
## ---
## fontsize: 30pt
## output:
##   html_document:
##     theme: readable
##     toc: true
##     toc_depth: 2
##     toc_float:
##       collapsed: no
##     code_folding: hide
## ---
## 
## <style type="text/css">
## 
## body{ /* Normal  */
##       font-size: 24px;
##   }
## </style>

## ----fig.stationarity, fig.height = 4, fig.width = 8, fig.align = "center", echo=FALSE----
require(gridExtra)
require(reshape2)

TT=100
y = rnorm(TT)
dat = data.frame(t=1:TT, y=y)
p1 = ggplot(dat, aes(x=t, y=y)) + geom_line() + 
  ggtitle("White Noise") + xlab("") + ylab("value")
ys = matrix(rnorm(TT*10),TT,10)
ys = data.frame(ys)
ys$id = 1:TT

ys2=melt(ys, id.var="id")
p2 = ggplot(ys2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("The variance of a white noise process is steady")
grid.arrange(p1, p2, ncol = 1)

## ----fig.stationarity2, fig.height = 4, fig.width = 8, fig.align = "center", echo=FALSE----
require(ggplot2)
require(reshape2)
theta=0.8
nsim=10
ar1=as.vector(arima.sim(TT, model=list(ar=theta)))
dat = data.frame(t=1:TT, y=ar1)
p1 = ggplot(dat, aes(x=t, y=y)) + geom_line() + 
  ggtitle("AR-1") + xlab("") + ylab("value")
ys = matrix(0,TT,nsim)
for(i in 1:nsim) ys[,i]=as.vector(arima.sim(TT, model=list(ar=theta)))
ys = data.frame(ys)
ys$id = 1:TT

ys2=melt(ys, id.var="id")
p2 = ggplot(ys2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("The variance of an AR-1 process is steady")
grid.arrange(p1, p2, ncol = 1)

## ----fig.stationarity3, fig.height = 4, fig.width = 8, fig.align = "center", echo=FALSE----
require(ggplot2)
require(gridExtra)
intercept = .5
trend=.1
dat = data.frame(t=1:TT, wn=rnorm(TT))
dat$wni = dat$wn+intercept
dat$wnti = dat$wn + trend*(1:TT) + intercept
p1 = ggplot(dat, aes(x=t, y=wn)) + geom_line() + ggtitle("White noise")
p2 = ggplot(dat, aes(x=t, y=wni)) + geom_line() + ggtitle("with non-zero mean")
p3 = ggplot(dat, aes(x=t, y=wnti)) + geom_line() + ggtitle("with linear trend")

ar1 = rep(0,TT)
err = rnorm(TT)
for(i in 2:TT) ar1[i]=theta*ar1[i-1]+err[i]
dat = data.frame(t=1:TT, ar1=ar1)
dat$ar1i = dat$ar1+intercept
dat$ar1ti = dat$ar1 + trend*(1:TT) + intercept
p4 = ggplot(dat, aes(x=t, y=ar1)) + geom_line() + ggtitle("AR1")
p5 = ggplot(dat, aes(x=t, y=ar1i)) + geom_line() + ggtitle("with non-zero mean")
p6 = ggplot(dat, aes(x=t, y=ar1ti)) + geom_line() + ggtitle("with linear trend")

grid.arrange(p1, p4, p2, p5, p3, p6, ncol = 2)

## ----fig.nonstationarity, fig.height = 4, fig.width = 8, fig.align = "center", echo=FALSE----
require(ggplot2)
require(reshape2)

rw = rep(0,TT)
for(i in 2:TT) rw[i]=rw[i-1]+err[i]
dat = data.frame(t=1:TT, rw=rw)
p1 = ggplot(dat, aes(x=t, y=rw)) + geom_line() + 
  ggtitle("Random Walk") + xlab("") + ylab("value")
rws = apply(matrix(rnorm(TT*nsim),TT,nsim),2,cumsum)
rws = data.frame(rws)
rws$id = 1:TT

rws2=melt(rws, id.var="id")
p2 = ggplot(rws2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("The variance of a random walk process grows in time")
grid.arrange(p1, p2, ncol = 1)

## ----fig.stationarity4, fig.height = 4, fig.width = 8, fig.align = "center", echo=FALSE----
require(ggplot2)
require(gridExtra)
dat = data.frame(t=1:TT, y=cumsum(rnorm(TT)))
dat$yi = cumsum(rnorm(TT,intercept,1))
dat$yti = cumsum(rnorm(TT,intercept+trend*1:TT,1))
p1 = ggplot(dat, aes(x=t, y=y)) + geom_line() + ggtitle("Random Walk")
p2 = ggplot(dat, aes(x=t, y=yi)) + geom_line() + ggtitle("with non-zero mean added")
p3 = ggplot(dat, aes(x=t, y=yti)) + geom_line() + ggtitle("with linear trend added")

grid.arrange(p1, p2, p3, ncol = 1)

## ----fig.vis, fig.height = 4, fig.width = 8, fig.align = "center", echo=FALSE----
require(ggplot2)
dat = subset(landings, Species %in% c("Anchovy", "Sardine") & 
               Year <= 1989)
dat$log.metric.tons = log(dat$metric.tons)
ggplot(dat, aes(x=Year, y=log.metric.tons)) +
  geom_line()+facet_wrap(~Species)

## ----fig.df, fig.height = 6, fig.width = 8, fig.align = "center", echo=FALSE----
require(ggplot2)
require(gridExtra)
#####
ys = matrix(0,TT,nsim)
for(i in 2:TT) ys[i,]=ys[i-1,]+rnorm(nsim)
rws = data.frame(ys)
rws$id = 1:TT
library(reshape2)
rws2=melt(rws, id.var="id")
p1 = ggplot(rws2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("Null Non-stationary", subtitle="White noise")
ys = matrix(0,TT,nsim)
for(i in 2:TT) ys[i,]=theta*ys[i-1,]+rnorm(nsim)
ar1s = data.frame(ys)
ar1s$id = 1:TT
library(reshape2)
ar1s2=melt(ar1s, id.var="id")
p2 = ggplot(ar1s2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("Alternate Stationary", subtitle="AR1")
#####
ys = matrix(intercept,TT,nsim)
for(i in 2:TT) ys[i,]=intercept+ys[i-1,]+rnorm(nsim)
rws = data.frame(ys)
rws$id = 1:TT
library(reshape2)
rws2=melt(rws, id.var="id")
p3 = ggplot(rws2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("", subtitle="White noise + drift")
ys = matrix(intercept/(1-theta),TT,nsim)
for(i in 2:TT) ys[i,]=intercept+theta*ys[i-1,]+rnorm(nsim)
ar1s = data.frame(ys)
ar1s$id = 1:TT
library(reshape2)
ar1s2=melt(ar1s, id.var="id")
p4 = ggplot(ar1s2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("Alternate", subtitle="AR1 + non-zero level")
#####
ys = matrix(intercept+trend*1,TT,nsim)
for(i in 2:TT) ys[i,]=intercept+trend*i+ys[i-1,]+rnorm(nsim)
rws = data.frame(ys)
rws$id = 1:TT
library(reshape2)
rws2=melt(rws, id.var="id")
p5 = ggplot(rws2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("", subtitle="White noise + exponential drift")
ys = matrix((intercept+trend*1)/(1-theta),TT,nsim)
for(i in 2:TT) ys[i,]=intercept+trend*i+theta*ys[i-1,]+rnorm(nsim)
ar1s = data.frame(ys)
ar1s$id = 1:TT
library(reshape2)
ar1s2=melt(ar1s, id.var="id")
p6 = ggplot(ar1s2, aes(x=id,y=value,group=variable)) +
  geom_line() + xlab("") + ylab("value") +
  ggtitle("Alternate", subtitle="AR1 + linear trend")
#####
grid.arrange(p1, p2, p3, p4, p5, p6, ncol = 2)

## ----adf.test.anchovy1---------------------------------------------------
adf.test(anchovy, k=0)

## ----dickey.fuller, message=FALSE, warning=FALSE-------------------------
require(urca)
test = ur.df(anchovy, type="trend", lags=0)
test

## ----teststat------------------------------------------------------------
attr(test, "teststat")

## ----cval----------------------------------------------------------------
attr(test,"cval")

## ----dickey.fuller2, message=FALSE, warning=FALSE------------------------
require(tseries)
adf.test(anchovy)

## ----dickey.fuller.ur.df, message=FALSE, warning=FALSE-------------------
require(urca)
k = trunc((length(anchovy)-1)^(1/3))
test = ur.df(anchovy, type="trend", lags=k)
test

## ----kpss.test, message=FALSE, warning=FALSE-----------------------------
require(tseries)
kpss.test(anchovy, null="Trend")

## ----diff1---------------------------------------------------------------
x <- diff(c(1,2,4,7,11))
x

## ----diff2---------------------------------------------------------------
diff(x)

## ----diff1.plot, fig.align="center", fig.height = 4, fig.width = 8-------
par(mfrow=c(1,2))
plot(anchovy, type="l")
title("Anchovy")
plot(diff(anchovy), type="l")
title("Anchovy first difference")

## ----diff.anchovy.test---------------------------------------------------
diff.anchovy = diff(anchovy)
kpss.test(diff.anchovy)

## ----test.dickey.fuller.diff1--------------------------------------------
adf.test(diff.anchovy)

## ----test.dickey.fuller.diff2--------------------------------------------
test <- ur.df(diff.anchovy, type="drift", lags=2)

## ----teststat.diff-------------------------------------------------------
attr(test, "teststat")

## ----cval.diff-----------------------------------------------------------
attr(test,"cval")

