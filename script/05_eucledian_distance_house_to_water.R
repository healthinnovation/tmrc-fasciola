library(sf)
library(tidyverse)
library(qgisprocess)

# 1. Reading of csv layer of villages --------------------------------
house <- read_csv("output/processed_house_data.csv")
waterbodies <- read_csv("output/processed_water_bodies.csv")
name_output <- "output"  # Export csv final 

# 2. Calculate of matrix distance ---------------------------------------
house_sp <- house |> 
  st_as_sf(coords = c('lng','lat'),crs = 4326) |> 
  st_transform(crs = 32718) 

waterbodies_sp <- waterbodies |> 
  st_as_sf(coords = c('lng','lat'),crs = 4326) |> 
  st_transform(32718)

distance_min <- function(x){
  min_distance <- 
    st_nearest_points(
      house_sp[x,],
      waterbodies_sp) |> 
    st_as_sf() |> 
    rename(geometry = x) |> 
    mutate(
      id_from = house_sp[x,]$id_hogar,
      id_to = waterbodies_sp$id_hogar,
      distance_m = as.vector(st_length(geometry))) |> 
    filter(distance_m != 0) |> 
    arrange(distance_m) |> 
    first()
}

list_distance <- lapply(X = 1:nrow(house_sp),FUN = distance_min) |> 
  map_df(.f = as_tibble)

# 3. Exporting the new database of distances of the waterbodies ------------
if(!dir.exists(name_output)){dir.create(name_output)}
write_csv(
  list_distance,
  sprintf('%s/%s',name_output,'processed_euclidist_house_to_waterbodies.csv'))