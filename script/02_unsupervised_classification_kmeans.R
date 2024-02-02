library(qgisprocess)
library(terra)

# 1. Defined parameters ---------------------------------------------------
path_rgb <- "Primera Salida/Huayllapata/huayllapata_D.tif"
name_output<- "ouput"
name_community <- "huayllapata"

# 2. Kmeans SAGA Method ---------------------------------------------------
if(!dir.exists(name_output)){dir.create(name_output)}
rgb <- rast(path_rgb)
kmeans_saga <- qgis_function(algorithm = "sagang:kmeansclusteringforgrids")
community_cluster <- kmeans_saga(
  GRIDS = qgis_list_input(
    rgb[[1]],
    rgb[[2]],
    rgb[[3]]
    ),
  CLUSTER = sprintf('%s/%s_cluster.tif',name_output,name_community),
  STATISTICS = sprintf('%s/%s_stats_cluster.csv',name_output,name_community),
  METHOD = 1,
  NCLUSTER = 5,
  NORMALISE = TRUE) |> 
  qgis_extract_output(name = "CLUSTER") |> 
  qgis_as_terra()
