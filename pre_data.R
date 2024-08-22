library(sf)
churo <- st_read("data/datos/churo_variables.gpkg") |> mutate(ccpp_name = "Churo", id = paste0(id,'_',ccpp_name))
huaccaycancha <- st_read("data/datos/huaccaycancha_variables.gpkg") |> mutate(ccpp_name = "Huaccaycancha",id = paste0(id,'_',ccpp_name)) 
huayllapata <- st_read("data/datos/huayllapata_variables.gpkg") |> mutate(ccpp_name = "Huayllapata",id = paste0(id,'_',ccpp_name))
ohuay <- st_read("data/datos/ohuay_variables.gpkg") |> mutate(ccpp_name = "Ohuay",id = paste0(id,'_',ccpp_name))

base <- bind_rows(churo,huaccaycancha,huayllapata,ohuay) |> 
  select(id,ccpp_name,8:21)

base_geo <- base |> 
  select(id)
write_sf(base_geo,'ddbbss/base_geo.gpkg')

base_nogeo <- base |> 
  st_drop_geometry()

write_csv(base_nogeo,'ddbbss/spatial_data_base_cusco.csv')