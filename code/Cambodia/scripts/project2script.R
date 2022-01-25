rm(list=ls(all=TRUE))

# install.packages("raster", dependencies = TRUE)
# install.packages("sf", dependencies = TRUE)
# install.packages("tidyverse", dependencies = TRUE)
# install.packages("doParallel", dependencies = TRUE)
# install.packages("snow", dependencies = TRUE)

library(sf)
library(raster)
library(tidyverse)
library(doParallel)
library(snow)

setwd("~/WM/DATA100/Cambodia")

load("data/khm_adm1.RData")
load("data/khm_adm2.RData")

f <- list.files(pattern="esaccilc_dst", recursive=TRUE)

lulc <- stack(lapply(f, function(i) raster(i, band=1)))

nms <- sub("_100m_2015", "", sub("lulc/khm_esaccilc_", "", f))

names(lulc) <- nms

topo <- raster("data/khm_srtm_topo_100m.tif")
slope <- raster("data/khm_srtm_slope_100m.tif")
ntl <- raster("data/khm_viirs_100m_2015.tif")

lulc <- addLayer(lulc, topo, slope, ntl)
save(lulc, file = "lulc.RData")
names(lulc)[c(1:12)] <- c("water","dst011.tif","dst040.tif","dst130.tif","dst140.tif","dst150.tif","dst160.tif","dst190.tif","dst200.tif","topo","slope", "ntl")

plot(lulc[[12]])

plot(lulc[[8]])
plot(st_geometry(khm_adm1), add = TRUE)

plot(lulc[[10]])                
contour(lulc[[10]], add = TRUE)

ncores <- detectCores() - 1
beginCluster(ncores)
lulc_vals_adm2 <- raster::extract(lulc, khm_adm2, df = TRUE)
endCluster

load("data/lulc_vals_adm2.RData")

lulc_ttls_adm2 <- lulc_vals_adm2 %>%
  group_by(ID) %>%
  summarize_all(sum, na.rm = TRUE)

khm_adm2 <- bind_cols(khm_adm2, lulc_ttls_adm2)

ggplot(khm_adm2, aes(ntl)) +
  geom_histogram(aes(y = ..density..), color = "black", fill = "white") + 
  geom_density(alpha = 0.2, fill = "#FF6666") + 
  theme_minimal()

ggplot(khm_adm2, aes(pop19, ntl)) + 
  geom_point(size = .1, color = "red") +
  geom_smooth()

ggplot(lm(pop19 ~ water + dst011.tif + dst040.tif + dst130.tif + dst140.tif + dst150.tif + dst160.tif + dst190.tif + dst200.tif + topo + slope + ntl, data=khm_adm2)) + 
  geom_point(aes(x=.fitted, y=.resid), size = .1, color = "red") +
  geom_smooth(aes(x=.fitted, y=.resid))

fit <- (lm(pop19 ~ water + dst011.tif + dst040.tif + dst130.tif + dst140.tif + dst150.tif + dst160.tif + dst190.tif + dst200.tif + topo + slope + ntl, data=khm_adm2))
summary(fit)

fit$fitted.values
khm_adm2$pop19 - fit$fitted.values

model_data <- cbind.data.frame(name = khm_adm2$ADM2_EN, fitted = fit$fitted.values, residuals = khm_adm2$pop19 - fit$fitted.values)
ggplot(data = model_data, aes(x = fitted, y = residuals)) +
  geom_point(size = 0.25) +
  geom_smooth(size = 0.5) +
  geom_text(data = text,
            aes(x = fitted,
                y = residuals,
                label = name),
            size = 2,
            nudge_y = 2)

text <- subset(model_data, fitted > 250000)

