library(sf)
library(tidyverse)
library(leaflet)

# Input of parameters
path_water_body <- 'cusco-fasciola/agua_fasciola_gps.xlsx'
name_output <- 'output'

# Reading water bodies data 
water_bodies <- readxl::read_xlsx(path_water_body) |>
  janitor::clean_names() |> 
  separate(
    col = coordenada_corregida,
    sep = " ",
    into = c('lat','lng')) |> 
  mutate(
    lat = -1*as.numeric(str_extract(lat,pattern = "([0-9]+\\.[0-9]+)")),
    lng = -1*as.numeric(str_extract(lng,pattern = "([0-9]+\\.[0-9]+)"))) |> 
  select(
    id_hogar,
    id_sitioagua,
    id_magua,
    p_dpto,
    p_comunidad,
    presencia_de_caracol,
    lat,
    lng)

if(!dir.exists(name_output)){dir.create(name_output)}
write_csv(
  water_bodies,
  sprintf('%s/%s',name_output,'processed_water_bodies.csv'))

# Simple visualization of spatial data  

# water_bodies |> 
#   leaflet() |> 
#   addTiles() |> 
#   addMarkers()


# Reading snails position data 

## Churo 
path_snails_churo <- "cusco-fasciola/Coordenadas caracoles Churu.xlsx"
snails_churo <- readxl::read_xlsx(path_snails_churo) |> 
  janitor::clean_names() |> 
  separate(
    col = coordenadas_garmin_caracoles,
    sep = " ",
    into = c('lat','lng')) |> 
  mutate(
    lat = -1*as.numeric(str_extract(lat,pattern = "([0-9]+\\.[0-9]+)")),
    lng = -1*as.numeric(str_extract(lng,pattern = "([0-9]+\\.[0-9]+)")),
    comunidad = 'Churo') 

# write_csv(
#   snails_churo,
#   sprintf('%s/%s',name_output,'processed_snails_churo.csv'))

## Huayllapata 
path_snails_huayllapata <- "cusco-fasciola/Puntos caracoles Huayllapata.xlsx"
snails_huayllapata <- readxl::read_xlsx(path_snails_churo) |> 
  janitor::clean_names() |> 
  separate(
    col = coordenadas_garmin_caracoles,
    sep = " ",
    into = c('lat','lng')) |> 
  mutate(
    lat = -1*as.numeric(str_extract(lat,pattern = "([0-9]+\\.[0-9]+)")),
    lng = -1*as.numeric(str_extract(lng,pattern = "([0-9]+\\.[0-9]+)")),
    comunidad = 'Huayllapata') 

# write_csv(
#   snails_huayllapata,
#   sprintf('%s/%s',name_output,'processed_snails_huayllapata.csv'))

# New database of snails position

bind_rows(
  snails_churo,
  snails_huayllapata) |> 
  write_csv(sprintf('%s/%s',name_output,'processed_snails_position.csv'))