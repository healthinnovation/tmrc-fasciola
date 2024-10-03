library(sf)
library(tidyverse)
coords <- read_csv2("csv/data_maps_03_10_2024.csv") |> 
  janitor::clean_names() |> 
  separate(col = "cordenadas_en_kobo",sep = ",",into = c("lat","lon")) 

sp_coords <- coords |> 
  st_as_sf(coords = c("lon","lat"),crs = 4326)

write_sf(sp_coords,'data-processed/coordenas.gpkg')
