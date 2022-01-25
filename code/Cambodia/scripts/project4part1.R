rm(list=ls(all=TRUE))

#install.packages("rayshader", dependencies = TRUE)

library(raster)
library(sf)
library(tidyverse)

library(rayshader)
library(rayrender)
install.packages("rgl", repos="http://R-Forge.R-project.org")
library(rgl)
setwd("~/WM/DATA100/Cambodia")

#save(combined_adm2s, file = "combined_adm2s.RData")
#rm("combined_adm2s")
load("combined_adm2s.RData")
#save(combined_polys, file = "combined_polys.RData")
#rm("combined_polys")
load("combined_polys.RData")

khm_topo <- raster("data/khm_srtm_topo_100m.tif")
khm_adm2  <- read_sf("data/khm_admbnda_adm2_gov_20181004/khm_admbnda_adm2_gov_20181004.shp")

combined_topo <- crop(khm_topo, combined_adm2s)

combined_matrix <- raster_to_matrix(combined_topo)

combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix)) %>%
  plot_map()

ambientshadows <- ambient_shade(combined_matrix)

combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix), color = "lightblue") %>%
  add_shadow(ray_shade(combined_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(combined_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  add_overlay(overlay_img, alphalayer = 0.5) %>%
  plot_3d(combined_matrix, zscale = 10,windowsize = c(1000,1000), 
          phi = 35, theta = 30, zoom = 0.7, 
          background = "grey30", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -80)

rgl::rgl.clear()

render_snapshot(title_text = "Sanniquelleh-Mahn & Saclepea, Liberia", 
                title_size = 50,
                title_color = "grey90")
render_label(combined_matrix, "Krong Ban Lung", textcolor ="white", linecolor = "white", 
             x = 490, y = 155, z = 700, textsize = 2.5, linewidth = 4, zscale = 10)
obj <- ggplot() +
  geom_sf(data = combined_adm2s,
          size = 4.5,
          linetype = "11",
          color = "gold",
          alpha = 0) +
  geom_sf(data = combined_polys,
          size = 0.75,
          color = "gray50",
          fill = "gold1",
          alpha = 0.8) +
  geom_sf(data = primary,
          size = 2.5,
          color = "orange") +
  geom_sf(data = secondary,
          size = 2,
          color = "orange") +
  geom_sf(data = tertiary,
          size = 1.5,
          color = "orange") +
  geom_sf(data = khm_hcf,
          size = 10,
          color = "brown")+
  theme_void() + theme(legend.position="none") +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  labs(x=NULL, y=NULL, title=NULL)

png("combined.png", width = 1015, height = 780, units = "px", bg = "transparent")
obj
dev.off()


overlay_img <- png::readPNG("combined.png")

combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix)) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_map()



