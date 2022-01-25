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

khm_adm3 <- read_sf("data/khm_admbnda_adm3_gov_20181004/khm_admbnda_adm3_gov_20181004.shp")
load("data/lulc_vals_adm2.RData")
load("data/khm_adm0.RData")
load("data/khm_adm1.RData")
load("data/khm_adm2.RData")

#f <- list.files(pattern="esaccilc_dst", recursive=TRUE)
#lulc <- stack(lapply(f, function(i) raster(i, band=1)))
#nms <- sub("_100m_2015", "", sub("lulc/khm_esaccilc_", "", f))
#names(lulc) <- nms
#topo <- raster("data/khm_srtm_topo_100m.tif")
#slope <- raster("data/khm_srtm_slope_100m.tif")
#ntl <- raster("data/khm_viirs_100m_2015.tif")
#lulc <- addLayer(lulc, topo, slope, ntl)
#save(lulc, file = "lulc.RData")
#names(lulc)[c(1:12)] <- c("water","dst011.tif","dst040.tif","dst130.tif","dst140.tif","dst150.tif","dst160.tif","dst190.tif","dst200.tif","topo","slope", "ntl")
#lulc <- crop(lulc, khm_adm0)
#lulc <- mask(lulc, khm_adm0)

#writeRaster(lulc, filename = "lulc.tif", overwrite = TRUE)
#lulc <- stack("lulc.tif")
lulc <- brick("lulc.tif") #loads in lulc

names(lulc) <- c("water", "dst011" , "dst040", "dst130", "dst140", "dst150","dst160", "dst190", "dst200", "topo", "slope", "ntl")

#ncores <- detectCores() - 1
beginCluster(ncores)
#pop_vals_adm1 <- raster::extract(khm_pop15, khm_adm1, df = TRUE)
#pop_vals_adm2 <- raster::extract(khm_pop15, khm_adm2, df = TRUE)
#pop_vals_adm3 <- raster::extract(khm_pop15, khm_adm3, df = TRUE)
#endCluster()
save(pop_vals_adm1, pop_vals_adm2, pop_vals_adm3, file = "khm_pop_vals.RData")
load("khm_pop_vals.RData")

totals_adm2 <- pop_vals_adm2 %>%
   group_by(ID) %>%
   summarize(pop15 = sum(khm_ppp_2015, na.rm = TRUE))
 
khm_adm2 <- khm_adm2 %>%
   add_column(pop15 = totals_adm2$pop15)
 
khm_adm2 <- khm_adm2 %>%
   mutate(area = st_area(khm_adm2) %>%
            units::set_units(km^2)) %>%
   mutate(density = pop15 / area)

save(khm_adm1, khm_adm2, khm_adm3, file = "khm_adms.RData")
load("khm_adms.RData")

names(lulc) <- c("water", "dst011.tif" , "dst040.tif", "dst130.tif", "dst140.tif", "dst150.tif", 
                 "dst160.tif", "dst190.tif", "dst200.tif", "topo", "slope", "ntl")
#ncores <- detectCores() - 1
#beginCluster(ncores)
#lulc_vals_adm1 <- raster::extract(lulc, khm_adm1, df = TRUE)
#lulc_vals_adm2 <- raster::extract(lulc, khm_adm2, df = TRUE)
#lulc_vals_adm3 <- raster::extract(lulc, khm_adm3, df = TRUE)
#endCluster()
#save(lulc_vals_adm1, lulc_vals_adm2, file = "lulc_vals_adms.RData")

load("lulc_vals_adms.RData")

lulc_ttls_adm2 <- lulc_vals_adm2 %>%
   group_by(ID) %>%
   summarize_all(sum, na.rm = TRUE)

lulc_means_adm2 <- lulc_vals_adm2 %>%
   group_by(ID) %>%
   summarize_all(mean, na.rm = TRUE)
khm_adm2 <- bind_cols(khm_adm2, lulc_ttls_adm2, lulc_means_adm2)

save(khm_adm2, file = "khm_adm2.RData")

load("khm_adm2.RData")
model.sums <- lm(pop15 ~ water + dst011.tif + dst040.tif + dst130.tif + dst140.tif + dst150.tif + dst160.tif + dst190.tif + dst200.tif + topo + slope + ntl, data=khm_adm2)
model.means <- lm(pop15 ~ water1 + dst011.tif1 + dst040.tif1 + dst130.tif1 + dst140.tif1 + dst150.tif1 + dst160.tif1 + dst190.tif1 + dst200.tif1 + topo1 + slope1 + ntl1, data=khm_adm2)

khm_adm2$logpop15 <- log(khm_adm2$pop15)
khm_adm2$logpop15 <- log(khm_adm2$pop15)
model.logpop15 <- lm(logpop15 ~ water1 + dst011.tif1 + dst040.tif1 + dst130.tif1 + dst140.tif1 + dst150.tif1 + dst160.tif1 + dst190.tif1 + dst200.tif1 + topo1 + slope1 + ntl1, data=khm_adm2)

lulc1 <- lulc
names(lulc1) <- c("water1", "dst011.tif1" , "dst040.tif1", "dst130.tif1", "dst140.tif1", "dst150.tif1", "dst160.tif1", "dst190.tif1", "dst200.tif1", "topo1", "slope1", "ntl1")

#predicted_values_sums <- raster::predict(lulc, model.sums)
#predicted_values_means <- raster::predict(lulc1, model.means)
#predicted_values_logpop15 <- raster::predict(lulc1, model.logpop15)

#save(predicted_values_sums, predicted_values_means, predicted_values_logpop15, file = "predicted_values.RData")
load("predicted_values.RData")

#ncores <- detectCores() - 1
#beginCluster(ncores)
#pred_vals_adm2_sums <- raster::extract(predicted_values_sums, khm_adm2, df=TRUE)
#pred_vals_adm2_means <- raster::extract(predicted_values_means, khm_adm2, df=TRUE)
#pred_vals_adm2_logpop15 <- raster::extract(predicted_values_logpop15, khm_adm2, df=TRUE)
#endCluster()

#save(pred_vals_adm2_sums, pred_vals_adm2_means, pred_vals_adm2_logpop15, file = "predicted_values_adm2s.RData")
load("predicted_values_adm2s.RData")

pred_ttls_adm2_sums <- aggregate(. ~ ID, pred_vals_adm2_sums, sum)
pred_ttls_adm2_means <- aggregate(. ~ ID, pred_vals_adm2_means, sum)
pred_ttls_adm2_logpop15 <- aggregate(. ~ ID, pred_vals_adm2_logpop15, sum) #different values

ttls <- cbind.data.frame(preds_sums = pred_ttls_adm2_sums$layer, 
                         preds_means = pred_ttls_adm2_means$layer, 
                         resp_logpop = pred_ttls_adm2_logpop15$layer)

khm_adm2 <- bind_cols(khm_adm2, ttls)

predicted_totals_sums <- rasterize(khm_adm2, predicted_values_sums, field = "preds_sums")
predicted_totals_means <- rasterize(khm_adm2, predicted_values_means, field = "preds_means")
predicted_totals_logpop <- rasterize(khm_adm2, predicted_values_logpop15, field = "resp_logpop") #different values

gridcell_proportions_sums  <- predicted_values_sums / predicted_totals_sums
gridcell_proportions_means  <- predicted_values_means  / predicted_totals_means
gridcell_proportions_logpop  <- predicted_values_logpop15  / predicted_totals_logpop

cellStats(gridcell_proportions_sums, sum)
cellStats(gridcell_proportions_means, sum)
cellStats(gridcell_proportions_logpop, sum)

population_adm2 <- rasterize(khm_adm2, predicted_values_sums, field = "pop15")

population_sums <- gridcell_proportions_sums * population_adm2
population_means <- gridcell_proportions_means * population_adm2
population_logpop <- gridcell_proportions_logpop * population_adm2

cellStats(population_sums, sum)
cellStats(population_means, sum)
cellStats(population_logpop, sum)

sum(khm_adm2$pop15)

diff_sums <- population_sums - khm_pop15
diff_means <- population_means - khm_pop15
diff_logpop <- population_logpop - khm_pop15

plot(population_sums)
plot(diff_sums)
rasterVis::plot3D(diff_sums)
cellStats(abs(diff_sums), sum)

plot(population_means)
plot(diff_means)
rasterVis::plot3D(diff_means)
cellStats(abs(diff_means), sum)

plot(population_logpop)
plot(diff_logpop)
rasterVis::plot3D(diff_logpop)
cellStats(abs(diff_logpop), sum)

urban_adm2 <- khm_adm2 %>%
   filter(ADM1_EN == "Phnom Penh")
urban_diff <- mask(diff, urban_adm2)
urban_pop <- mask(population, urban_adm2)

rgl.snapshot("diff", fmt = "png", top = TRUE )