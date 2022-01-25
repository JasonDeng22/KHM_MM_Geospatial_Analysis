rm(list=ls(all=TRUE))

install.packages("tidyverse", dependencies = TRUE)
install.packages("sf", dependencies = TRUE)
install.packages("Rcpp", dependencies = TRUE)
install.packages("raster", dependencies = TRUE)
install.packages("doParallel", dependencies = TRUE)
install.packages("snow",dependencies = TRUE)
install.packages("rayshader", dependencies= TRUE)

setwd("D:/program files D/School/WILLIAM AND MARY/Data 100/data/Myanmar")

library(tidyverse)
library(sf)
library(raster)
library(Rcpp)
library(doParallel)
library(snow)
library(rayshader)
mmr_pop <- raster("mmr_ppp_2019.tif")
mmr_adm1 <-read_sf("mmr_polbnda2_adm1_250k_mimu/mmr_polbnda2_adm1_250k_mimu.shp")
mmr_adm2 <-read_sf("mmr_polbnda_adm2_250k_mimu/mmr_polbnda_adm2_250k_mimu.shp")

#plot(mmr_pop)
#plot(st_geometry(mmr_adm1), add = TRUE)

ncores <- detectCores()-1
beginCluster(ncores)
pop_vals_adm2 <- raster::extract(mmr_pop, mmr_adm2, df = TRUE)
endCluster()

# save(pop_vals_adm1, file = "pop_vals_adm1.RData")
load("pop_vals_adm1.RData")
#save(pop_vals_adm2, file = "pop_vals_adm2.RData")
load("pop_vals_adm2.RData")

totals_adm1 <- pop_vals_adm1 %>% #wtf is this
  group_by(ID) %>%
  summarize(totals_adm1 = sum(mmr_ppp_2019, na.rm = TRUE))
totals_adm2 <- pop_vals_adm2 %>% #wtf is this
  group_by(ID) %>%
  summarize(totals_adm2 = sum(mmr_ppp_2019, na.rm = TRUE))

#sum(totals_adm1) to find the total population after adding every single variable in totals_adm1
#what the hell is a %>% operator, ask professor
mmr_adm1 <- mmr_adm1 %>%
  add_column(pop19 = totals_adm1$totals_adm1)

mmr_adm2 <- mmr_adm2 %>%
  add_column(popu19 = totals_adm2$totals_adm2)

ggplot(mmr_adm2) +
  geom_sf(data = mmr_adm2,
          size = .1,
          color = "black",
          fill = NA,
          alpha = .5) +
  geom_sf(aes(fill = log(popu19))) +
  scale_fill_gradient(low = "lightskyblue", high = "dodgerblue4") +
  geom_sf(data = mmr_adm1,
          size = .5,
          color = "black",
          fill = NA,
          alpha = 1)+ 
  geom_sf_text(data = mmr_adm1, aes(label = ST),
               color = "black",
               size = 2) +
  geom_sf_text(data = mmr_adm2, aes(label = mmr_adm2$DT),
               color = "black",
               size = 1) 

ggmmr_adm2 <- ggplot(mmr_adm2) +
  geom_sf(aes(fill = log(popu19))) +
  scale_fill_gradient(low = "lightskyblue", high = "dodgerblue4")

plot_gg(ggmmr_adm2, multicore = TRUE, width = 6 ,height=2.7, fov = 70)
render_movie(myanmar.mp4)

ggsave("mmr_logpop19.png")
