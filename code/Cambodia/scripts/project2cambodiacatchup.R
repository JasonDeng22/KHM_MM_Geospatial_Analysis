rm(list=ls(all=TRUE))

#install.packages("tidyverse", dependencies = TRUE)
#install.packages("sf", dependencies = TRUE)
#install.packages("Rcpp", dependencies = TRUE)
#install.packages("raster", dependencies = TRUE)
#install.packages("doParallel", dependencies = TRUE)
#install.packages("snow",dependencies = TRUE)

setwd("~/William and Mary/DATA100/Cambodia/data")

library(tidyverse)
library(sf)
library(raster)
library(Rcpp)
library(doParallel)
library(snow)

khm_adm0 <- read_sf("data/khm_admbnda_adm0_gov_20181004/khm_admbnda_adm0_gov_20181004.shp")
khm_adm1 <-read_sf("khm_admbnda_adm1_gov_20181004/khm_admbnda_adm1_gov_20181004.shp")
khm_adm2 <- read_sf("khm_admbnda_adm2_gov_20181004/khm_admbnda_adm2_gov_20181004.shp")
khm_pop <- raster("khm_ppp_2019.tif")

ncores <- detectCores()-1
beginCluster(ncores)
pop_vals_adm1 <- raster::extract(khm_pop, khm_adm1, df = TRUE)
endCluster()

ncores <- detectCores()-1
beginCluster(ncores)
pop_vals_adm2 <- raster::extract(khm_pop, khm_adm2, df = TRUE)
endCluster()

# save(pop_vals_adm1, file = "pop_vals_adm1.RData")
load("pop_vals_adm1.RData")
#save(pop_vals_adm2, file = "pop_vals_adm2.RData")
load("pop_vals_adm2.RData")

totals_adm1 <- pop_vals_adm1 %>%
  group_by(ID) %>%
  summarize(totals_adm1 = sum(khm_ppp_2019, na.rm = TRUE))
totals_adm2 <- pop_vals_adm2 %>%
  group_by(ID) %>%
  summarize(totals_adm2 = sum(khm_ppp_2019, na.rm = TRUE))

khm_adm1 <- khm_adm1 %>%
  add_column(pop19 = totals_adm1$totals_adm1)

khm_adm2 <- khm_adm2 %>%
  add_column(pop19 = totals_adm2$totals_adm2)

khm_adm1 <- khm_adm1 %>%
  mutate(area = sf::st_area(khm_adm1) %>%
           units::set_units(km^2)) %>%
  mutate(density = pop19/area)

khm_adm2 <- khm_adm2 %>%
  mutate(area = sf::st_area(khm_adm2) %>%
           units::set_units(km^2)) %>%
  mutate(density = pop19/area)

#save(khm_adm0, file = "khm_adm0.RData")
load("khm_adm1.RData")

#save(khm_adm1 , file = "khm_adm1.RData")
load("khm_adm1.RData")

#save(khm_adm2 , file = "khm_adm2.RData")
load("khm_adm2.RData")
