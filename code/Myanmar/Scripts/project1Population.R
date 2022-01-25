rm(list=ls(all=TRUE))

#install.packages("tidyverse", dependencies = TRUE)
#install.packages("sf", dependencies = TRUE)
#install.packages("Rcpp", dependencies = TRUE)
#install.packages("raster", dependencies = TRUE)
#install.packages("doParallel", dependencies = TRUE)
#install.packages("snow",dependencies = TRUE)

setwd("D:/program files D/School/WILLIAM AND MARY/Data 100/data/Myanmar")

library(tidyverse)
library(sf)
library(raster)
library(Rcpp)
library(doParallel)
library(snow)

mmr_pop <- raster("mmr_ppp_2019.tif")
mmr_adm1 <-read_sf("mmr_polbnda2_adm1_250k_mimu/mmr_polbnda2_adm1_250k_mimu.shp")

#plot(mmr_pop)
#plot(st_geometry(mmr_adm1), add = TRUE)

ncores <- detectCores()-1
beginCluster(ncores)

pop_vals_adm1 <- raster::extract(mmr_pop, mmr_adm1, df = TRUE)
endCluster()

# save(pop_vals_adm1, file = "pop_vals_adm1.RData")
load("pop_vals_adm1.RData")

totals_adm1 <- pop_vals_adm1 %>% #wtf is this
  group_by(ID) %>%
  summarize(totals_adm1 = sum(mmr_ppp_2019, na.rm = TRUE))

#sum(totals_adm1) to find the total population after adding every single variable in totals_adm1
#what the hell is a %>% operator, ask professor

mmr_adm1 <- mmr_adm1 %>%
  add_column(pop19 = totals_adm1$totals_adm1)

ggplot(mmr_adm1)+
  geom_sf(aes(fill = pop19)) +
  geom_sf_text(aes(label = ST),
               color = "black",
               size = 1) +
  scale_fill_gradient(low="yellow",high = "red")
  
ggsave("mmr_pop19.png")


