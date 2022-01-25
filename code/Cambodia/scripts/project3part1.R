

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


khm_koun <- khm_adm2 %>%
  filter(ADM2_EN == "Koun Mom")

khm_koun_pop15 <- crop(khm_pop15, khm_koun)
khm_koun_pop15 <- mask(khm_koun_pop15, khm_koun)

pop <- floor(cellStats(khm_koun_pop15, 'sum'))
st_write(khm_koun, "khm_koun.shp", delete_dsn=TRUE)
koun_mt <- readShapeSpatial("khm_koun.shp")
win <- as(koun_mt, "owin")
khm_koun_ppp <- rpoint(pop, f = as.im(khm_koun_pop15), win = win)


#bw2 <- bw.ppl(khm_koun_ppp)
#save(bw2, file = "bw2.RData")
load("bw2.RData")

khm_koun_density <- density.ppp(khm_koun_ppp, sigma = bw2)

Dsg <- as(khm_koun_density, "SpatialGridDataFrame")  # convert to spatial grid class
Dim <- as.image.SpatialGridDataFrame(Dsg)  # convert again to an image
Dcl <- contourLines(Dim, levels = 450000)  # create contour object
SLDF <- ContourLines2SLDF(Dcl, CRS("+proj=longlat +datum=WGS84 +no_defs"))

SLDFs <- st_as_sf(SLDF, sf)

#png("KHM_dsg_contou1r.png", width = 750, height = 750)
#plot(Dsg, main = NULL)
#plot(SLDFs, add = TRUE)
#dev.off()

inside_polys <- st_polygonize(SLDFs)
outside_lines <- st_difference(SLDFs, inside_polys)

outside_buffers <- st_buffer(outside_lines, 0.001)
outside_intersects <- st_difference(khm_koun, outside_buffers)
oi_polys <- st_cast(outside_intersects, "POLYGON")
in_polys <- st_collection_extract(inside_polys, "POLYGON")
in_polys[ ,1] <- NULL
oi_polys[ ,1:16] <- NULL

all_polys1 <- st_union(in_polys, oi_polys)
all_polys1 <- st_collection_extract(all_polys1, "POLYGON")
all_polys1 <- st_cast(all_polys1, "POLYGON")

all_polys_koun <- all_polys1 %>%
  unique()

all_polys_sp_ext1 <- raster::extract(khm_koun_pop15, all_polys_koun, df = TRUE)

all_polys_sp_ttls1 <- all_polys_sp_ext1 %>%
  group_by(ID) %>%
  summarize(pop15 = sum(khm_ppp_2015, na.rm = TRUE))

all_polys_koun <- all_polys_koun %>%
  add_column(pop15 = all_polys_sp_ttls1$pop15) %>%
  mutate(area = as.numeric(st_area(all_polys_koun) %>%
                             units::set_units(km^2))) %>%
  mutate(density = as.numeric(pop15 / area))

all_polys_koun <- all_polys_koun %>%
  filter(density > 40) %>%
  filter(density < 200)

sp_cntr_pts <-  all_polys_koun %>% 
  st_centroid() %>% 
  st_cast("MULTIPOINT")

ggplot() +
  geom_sf(data = khm_koun,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_koun,
          fill = "lightblue",
          size = 0.25,
          alpha = 0.5) +
  geom_sf(data = sp_cntr_pts,
          aes(size = pop15,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Urbanized Areas throughout Koun Mom, Cambodia")

combined_adm2s <- khm_lump %>%
  st_union(khm_koun) %>%
  summarize()

combined_polys <- all_polys_lump %>% 
  st_union(all_polys_koun) %>%
  summarize() %>% 
  st_cast("POLYGON")

comb_raster <- merge(khm_koun_pop15, khm_lump_pop15)
combined_ext <- raster::extract(comb_raster, combined_polys, df = TRUE)
combined_ttls <- combined_ext %>%
  group_by(ID) %>%
  summarize(pop15 = sum(layer, na.rm = TRUE))
combined_polys <- combined_polys %>%
  add_column(pop15 = combined_ttls$pop15) %>%
  mutate(area = as.numeric(st_area(combined_polys) %>%
                             units::set_units(km^2))) %>%
  mutate(density = as.numeric(pop15 / area))

combined_polys <- combined_polys %>%
  filter(density > 40) %>%
  filter(density < 175)

combined_pts <-  combined_polys %>% 
  st_centroid() %>% 
  st_cast("MULTIPOINT")

ggplot() +
  geom_sf(data = combined_adm2s,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = combined_polys,
          fill = "lightblue",
          size = 0.25,
          alpha = 0.5) +
  geom_sf(data = combined_pts,
          aes(size = pop15,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Urbanized Areas throughout Koun Mom & Lamphat, Cambodia")