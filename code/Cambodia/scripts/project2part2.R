rm(list=ls(all=TRUE))

# install.packages("raster", dependencies = TRUE)
# install.packages("sf", dependencies = TRUE)
# install.packages("tidyverse", dependencies = TRUE)
# install.packages("doParallel", dependencies = TRUE)
# install.packages("snow", dependencies = TRUE)
#install.packages("rgl", dependencies = TRUE)
#install.packages("rasterVis", dependencies = TRUE)
#install.packages("tmap", dependencies = TRUE)

library(sf)
library(raster)
library(tidyverse)
library(doParallel)
library(snow)
library(rgl)
library(rasterVis)
library(tmap)

setwd("~/WM/DATA100/Cambodia")

load("data/lulc_vals_adm2.RData")
load("data/khm_adm0.RData")
load("data/khm_adm1.RData")
load("data/khm_adm2.RData")
load("data/lulc.RData")

khm_pop15 <- raster("data/khm_ppp_2015.tif")

lulc <- mask(lulc, khm_adm0)

model <- (lm(pop19 ~ water + dst011.tif + dst040.tif + dst130.tif + dst140.tif + dst150.tif + dst160.tif + dst190.tif + dst200.tif + topo + slope + ntl, data=khm_adm2))
summary(model)

predicted_values <- predict(lulc, model, progress="window")
base <- predicted_values - minValue(predicted_values)
cellStats(base, sum)

ncores <- detectCores() - 1
beginCluster(ncores)
pred_vals_adm2 <- raster::extract(predicted_values, khm_adm2, df=TRUE)
endCluster()

pred_ttls_adm2 <- aggregate(. ~ ID, pred_vals_adm2, sum)
khm_adm2 <- bind_cols(khm_adm2, pred_ttls_adm2)

lulcNew <- rasterize(khm_adm2, predicted_values, field = "layer")
lulcNew2 <- predicted_values / lulcNew
lulcNew3 <- rasterize(khm_adm2, predicted_values, field = "pop19")

population <- lulcNew2 * lulcNew3

diff <-population - khm_pop15

cellStats(abs(diff), sum)
plot(diff)

urban_adm2 <- khm_adm2 %>%
  filter(ADM1_EN == "Phnom Penh")
urban2_adm2 <- khm_adm2 %>%
  filter(ADM2_EN == "Siem Reap")

  
urban_diff <- mask(diff, urban_adm2)
urban_pop <- mask(population, urban_adm2)
urban2_diff <- mask(diff, urban2_adm2)
urban2_pop <- mask(population, urban2_adm2)

extGMN <- c(104.5, 105.4, 11.2, 12)
gPP_diff <- crop(gPP_diff, extGMN)
gPP_pop <- crop(gPP_pop, extGMN)
plot(gPP_diff)
plot(gPP_pop)

extGMN <- c(103.5, 104.5, 13, 14)
gPP2_diff <- crop(urban2_diff, extGMN)
gPP2_pop <- crop(urban2_pop, extGMN)
plot(gPP2_diff)
plot(gPP2_pop)

rasterVis::plot3D(gPP_pop)

mapview::mapview(gPP_diff, alpha = .5)
mapview::mapview(gPP_pop, alpha = .5)
mapview::mapview(gPP2_diff, alpha = .5)
mapview::mapview(gPP2_pop, alpha = .5)




