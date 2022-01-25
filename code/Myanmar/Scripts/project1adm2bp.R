rm(list=ls(all=TRUE))

# install.packages("tidyverse", dependencies = TRUE)
# install.packages("sf", dependencies = TRUE)
# install.packages("units", dependencies = TRUE)
# install.packages("scales", dependencies = TRUE)
# install.packages("ggpubr", dependencies = TRUE)
# install.packages("ggrepel", dependencies = TRUE)

library(tidyverse)
library(sf)
library(units)
library(scales)
library(ggpubr)
library(ggrepel)

setwd("D:/program files D/School/WILLIAM AND MARY/Data 100/data/Myanmar")

#mmr_adm2 <-read_sf("mmr_polbnda_adm2_250k_mimu/mmr_polbnda_adm2_250k_mimu.shp")
#save(mmr_adm2 , file = "mmr_adm2.RData")
load("mmr_adm2.RData")

load("pop_vals_adm2.RData")

totals_adm2 <- pop_vals_adm2 %>% #wtf is this
  group_by(ID) %>%
  summarize(totals_adm2 = sum(mmr_ppp_2019, na.rm = TRUE))

mmr_adm2 <- mmr_adm2 %>%
  add_column(pop19 = totals_adm2$totals_adm2)

mmr_adm2 <- mmr_adm2 %>%
  mutate(area = sf::st_area(mmr_adm2) %>%
           units::set_units(km^2)) %>%
  mutate(density = pop19/area)

mmr_adm2 %>%
  ggplot(aes(x=ST, y=pop19, weight = pop19, fill = DT)) +
  geom_bar(stat="identity", color="blue", width=.75) +
  coord_flip() +
  theme(legend.position = "none") +
  geom_text_repel(aes(label = DT),
                  position = position_stack(vjust = 0.5),
                  force = 0.0005,
                  direction = "y",
                  size = 1.35,
                  segment.size = .2,
                  segment.alpha = .4)

ggsave("mmr_adm2_bp.png", width = 20, height = 15, dpi = 300)
