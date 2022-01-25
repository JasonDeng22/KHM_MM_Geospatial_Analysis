rm(list=ls(all=TRUE))

# install.packages("tidyverse", dependencies = TRUE)
# install.packages("sf", dependencies = TRUE)
# install.packages("units", dependencies = TRUE)
# install.packages("scales", dependencies = TRUE)
# install.packages("ggpubr", dependencies = TRUE)
library(tidyverse)
library(sf)
library(units)
library(scales)
library(ggpubr)

setwd("D:/program files D/School/WILLIAM AND MARY/Data 100/data/Myanmar")

#mmr_adm1 <-read_sf("mmr_polbnda2_adm1_250k_mimu/mmr_polbnda2_adm1_250k_mimu.shp")
#save(mmr_adm1 , file = "mmr_adm1.RData")
load("mmr_adm1.RData")

mmr_adm1 <- mmr_adm1 %>%
  mutate(area = sf::st_area(mmr_adm1) %>%
    units::set_units(km^2)) %>%
  mutate(density = pop19/area)

mmr_adm1 %>%
  mutate(ST = fct_reorder(ST, pop19)) %>%
  ggplot(aes(x = ST, y = pop19, fill = pop19)) +
  geom_bar(stat="identity", color = NA, width = .7) +
  coord_flip() +
  ggtitle("Population and Share of Population (in %)") +
  xlab ("country") + ylab("population") +
  geom_text(aes(label=percent(pop19/sum(pop19))),
            position = position_stack(vjust = 0.5),
            color = "black", size=3) +
  scale_fill_gradient(low = "lightskyblue", high = "dodgerblue4")

ggarrange(mmr_mapreal, mmr_bplt, nrow = 1, widths = c(5,5))

annotate_figure(myanmar, top = text_grob("Myanmar in 2019", color = "black", face = "bold", size = 26))




ggsave()
