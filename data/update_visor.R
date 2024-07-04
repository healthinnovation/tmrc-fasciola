library(rgee)
library(sf)
library(tidyverse)
ee_Initialize()

# Churo
churo_sp <- st_read("data/churo.gpkg") |> st_zm() |> sf_as_ee()
churo <- ee$Image("users/ambarja/cusco/churu")$clip(churo_sp)
churo_token <- Map$addLayer(churo)

# Ohuay
ohuay_sp <- st_read("data/ohuay.gpkg") |> st_zm() |> sf_as_ee()
ohuay <- ee$Image("users/ambarja/cusco/ohuay")$clip(ohuay_sp)
ohuay_token <- Map$addLayer(ohuay)

# Huayllapata
huayllapata_sp <- st_read("data/huayllapata.gpkg") |> st_zm() |> sf_as_ee()
huayllapata <- ee$Image("users/ambarja/cusco/huayllapata")$clip(huayllapata_sp)
huayllapata_token <- Map$addLayer(huayllapata)

# Huaccaycancha
huaccaycancha_sp <- st_read("data/huaccaycancha.gpkg") |> st_zm() |> sf_as_ee()
huaccaycancha <- ee$Image("users/ambarja/cusco/huaccaycancha")$clip(huaccaycancha_sp)
huaccaycancha_token <- Map$addLayer(huaccaycancha)

# Dataset
csv_drones <- tibble(
  rgb = c('churo','ohuay','huayllapata','huaccaycancha'),
  url = c(churo_token$rgee$tokens,ohuay_token$rgee$tokens,huayllapata_token$rgee$tokens,huaccaycancha_token$rgee$tokens)
)
write_csv(csv_drones,'data/drones-gee.csv')