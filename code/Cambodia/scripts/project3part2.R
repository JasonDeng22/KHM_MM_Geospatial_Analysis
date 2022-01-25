rm(list=ls(all=TRUE))

rm("khm_hcf")
# install.packages("raster", dependencies = TRUE)
# install.packages("sf", dependencies = TRUE)
# install.packages("tidyverse", dependencies = TRUE)
# install.packages("maptools", dependencies = TRUE)
# install.packages("spatstat", dependencies = TRUE)

library(raster)
library(sf)
library(tidyverse)
library(maptools)
library(spatstat)

install.packages("osmdata")
library(osmdata)
hcf <- opq(bbox = st_bbox(combined_adm2s)) %>%
  add_osm_feature("amenity", c("hospital","clinic","dentist","doctors")) %>%
  osmdata_sf()
hcf_list <- hcf$osm_points
setwd("~/WM/DATA100/Cambodia")

khm_roads  <- read_sf("data/hotosm_khm_roads_lines_shp/hotosm_khm_roads_lines.shp")

khm_roads <- st_crop(khm_roads, khm_lump)

khm_hcf <- read_sf("data/cambodia-shapefiles/shapefiles/healthsites.shp")

khm_hcf <- st_crop(khm_hcf, khm_lump)

primary <- khm_roads %>%
  filter(highway == "primary")

secondary <- khm_roads %>%
  filter(highway == "secondary")

tertiary <- khm_roads %>%
  filter(highway == "tertiary")

x <- st_length(primary)
st_length(tertiary)
st_length(secondary)
ggplot() +
  geom_sf(data = combined_adm2s,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = combined_polys,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = primary,
          size = 1.5,
          color = "orange") +
  geom_sf(data = secondary,
          size = 1,
          color = "orange") +
  geom_sf(data = tertiary,
          size = .5,
          color = "orange") +
  geom_sf(data = khm_hcf,
          size = 5,
          color = "brown")+
  geom_sf(data = combined_pts,
          aes(size = pop15,
              color = density),
          show.legend = 'point') +
  geom_sf(data = hcf_list,
          aes(size = pop15,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red")+
  xlab("longitude") + ylab("latitude") +
  ggtitle("Access to healthcare facilities throughout Lumphat and Kuon Mom, Cambodia")