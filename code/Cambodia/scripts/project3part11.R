rm(list=ls(all=TRUE))

rm("all_polys)")
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

setwd("~/WM/DATA100/Cambodia")

khm_pop15 <- raster("data/khm_ppp_2015.tif")
khm_adm2  <- read_sf("data/khm_admbnda_adm2_gov_20181004/khm_admbnda_adm2_gov_20181004.shp")


khm_lump <- khm_adm2 %>%
  filter(ADM2_EN == "Lumphat")

khm_lump_pop15 <- crop(khm_pop15, khm_lump)
khm_lump_pop15 <- mask(khm_lump_pop15, khm_lump)

pop <- floor(cellStats(khm_lump_pop15, 'sum'))
lump_mt <- readShapeSpatial("khm_lump.shp")
win <- as(lump_mt, "owin")
khm_lump_ppp <- rpoint(pop, f = as.im(khm_lump_pop15), win = win)


#bw <- bw.ppl(khm_lump_ppp)
#save(bw, file = "bw.RData")
load("bw.RData")

khm_lump_density <- density.ppp(khm_lump_ppp, sigma = bw)

Dsg <- as(khm_lump_density, "SpatialGridDataFrame")  # convert to spatial grid class
Dim <- as.image.SpatialGridDataFrame(Dsg)  # convert again to an image
Dcl <- contourLines(Dim, levels = 790000)  # create contour object
SLDF <- ContourLines2SLDF(Dcl, CRS("+proj=longlat +datum=WGS84 +no_defs"))

SLDFs <- st_as_sf(SLDF, sf)

#png("KHM_dsg_contour.png", width = 750, height = 750)
#plot(Dsg, main = NULL)
#plot(SLDFs, add = TRUE)
#dev.off()

inside_polys <- st_polygonize(SLDFs)
outside_lines <- st_difference(SLDFs, inside_polys)

outside_buffers <- st_buffer(outside_lines, 0.001)
outside_intersects <- st_difference(khm_lump, outside_buffers)
oi_polys <- st_cast(outside_intersects, "POLYGON")
in_polys <- st_collection_extract(inside_polys, "POLYGON")
in_polys[ ,1] <- NULL
oi_polys[ ,1:16] <- NULL

all_polys <- st_union(in_polys, oi_polys)
all_polys <- st_collection_extract(all_polys, "POLYGON")
all_polys <- st_cast(all_polys, "POLYGON")


all_polys_lump <- all_polys %>%
  unique()

all_polys_sp_ext <- raster::extract(khm_lump_pop15, all_polys_lump, df = TRUE)

all_polys_sp_ttls <- all_polys_sp_ext %>%
  group_by(ID) %>%
  summarize(pop15 = sum(khm_ppp_2015, na.rm = TRUE))

all_polys_lump <- all_polys_lump %>%
  add_column(pop15 = all_polys_sp_ttls$pop15) %>%
  mutate(area = as.numeric(st_area(all_polys_lump) %>%
                             units::set_units(km^2))) %>%
  mutate(density = as.numeric(pop15 / area))

all_polys_lump <- all_polys_lump %>%
  filter(density > 35) %>%
  filter(density < 125)

sp_cntr_pts <-  all_polys_lump %>% 
  st_centroid() %>% 
  st_cast("MULTIPOINT")

ggplot() +
  geom_sf(data = khm_lump,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_lump,
          fill = "lightblue",
          size = 0.25,
          alpha = 0.5) +
  geom_sf(data = sp_cntr_pts,
          aes(size = pop15,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Urbanized Areas throughout Lumphat, Cambodia")

#ggsave("khm_lump.png", width = 10, height = 10)

