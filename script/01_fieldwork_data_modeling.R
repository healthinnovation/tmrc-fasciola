library(sf)
library(tidyverse)
library(leaflet)

# 1. Reading water bodies data  -------------------------------------------
path_water_body <- 'fieldwork_data_raw/agua_fasciola_gps.xlsx'
name_output <- 'output'
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

# 2. Reading snails position data -----------------------------------------

## Churo 
path_snails_churo <- "fieldwork_data_raw/Coordenadas caracoles Churu.xlsx"
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

## Huayllapata 
path_snails_huayllapata <- "fieldwork_data_raw/Puntos caracoles Huayllapata.xlsx"
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

# New database of snails position
bind_rows(
  snails_churo,
  snails_huayllapata) |> 
  write_csv(sprintf('%s/%s',name_output,'processed_snails_position.csv'))


# 3. Reading house data ---------------------------------------------------
path_house_data <- 'fieldwork_data_raw/hogar_fasciola_gps.xlsx'
house_data <- readxl::read_xlsx(path_house_data) |>
  select(id_hogar,h_fecha,'_h_gps_longitude','_h_gps_latitude')

names(house_data) <- c('id_hogar','fecha','lng','lat')
write_csv(house_data,sprintf('%s/%s',name_output,'processed_house_data.csv'))
