library(qgisprocess)
library(terra)
library(sf)

# 1. Defined parameters ---------------------------------------------------
name_output <- "covariable"
name_community <- "huayllapata"
spatial_data <- "geometry/huayllapata.kml"
# 2. Reading spatial data -------------------------------------------------

# Spatial geometry 
region <- st_read(spatial_data) |> st_transform(crs = 32718)

# Path of Bands
PATH_G <- "drone-image/huayllapata/huayllapata_G.tif"
PATH_R <- "drone-image/huayllapata/huayllapata_R.tif"
PATH_RE <- "drone-image/huayllapata/huayllapata_RE.tif"
PATH_NIR <- "drone-image/huayllapata/huayllapata_NIR.tif"
PATH_TEMP <- "drone-image/huayllapata/huayllapata_T_real.tif"
PATH_DEM <- "drone-image/huayllapata/huayllapata_DEM.tif"

# Reading data of the multispectral and thermal image drone
G <- rast(PATH_G)
R <- rast(PATH_R)
RE <- rast(PATH_RE)
NIR <- rast(PATH_NIR)
TEMP <- rast(PATH_TEMP)
DEM <- rast(PATH_DEM)

# Alignment of rasters based on the green band
G <- G |> crop(region, mask = TRUE)
R <- R |> crop(region, mask = TRUE) |> resample(G)
RE <- RE |> crop(region, mask = TRUE) |> resample(G)
NIR <- NIR |> crop(region, mask = TRUE) |> resample(G)
TEMP <- TEMP |> crop(region, mask = TRUE) |> resample(G)
DEM <- DEM |> crop(region, mask = TRUE) |> resample(G)

# New stack raster with 5 bands
stack_raster <- rast(list(G, R, RE, NIR, TEMP, DEM))
names(stack_raster) <- c("green", "red", "redge", "nir", "temp", "dem")

# Remove bands of list
rm(R);rm(RE);rm(NIR);rm(TEMP)

# 1. Environmental variables ----------------------------------------------
if(!dir.exists(name_output)){dir.create(name_output)}
veg_index <- qgis_function("sagang:vegetationindexslopebased")
veg_index(
  RED = stack_raster[["red"]],
  NIR = stack_raster[["nir"]],
  SAVI = sprintf("%s/%s_savi.tif", name_output, name_community),
  NDVI = sprintf("%s/%s_ndvi.tif", name_output, name_community),
  DVI = sprintf("%s/%s_dvi.tif", name_output, name_community),
  RVI = sprintf("%s/%s_rvi.tif", name_output, name_community),
  NRVI = sprintf("%s/%s_nrvi.tif", name_output, name_community),
  TVI =sprintf("%s/%s_tvi.tif", name_output, name_community),
  CTVI =sprintf("%s/%s_ctvi.tif", name_output, name_community),
  TTVI =sprintf("%s/%s_ttvi.tif", name_output, name_community)  
)

# 2. Topographic variables ------------------------------------------------
topo_index <- qgis_function("sagang:basicterrainanalysis")
topo_index(
  ELEVATION = stack_raster[["dem"]],
  SHADE = sprintf("%s/%s_shade.tif", name_output, name_community),
  SLOPE = sprintf("%s/%s_slope.tif", name_output, name_community),
  ASPECT = sprintf("%s/%s_aspect.tif", name_output, name_community),
  WETNESS = sprintf("%s/%s_wetness.tif", name_output, name_community),
  VALL_DEPTH = sprintf("%s/%s_vall_depth.tif", name_output, name_community),
)

morfo_index <- qgis_function("sagang:morphometricfeatures")
morfo_index(
  DEM = stack_raster[["dem"]],
  PLANC = sprintf("%s/%s_curvature.tif", name_output, name_community)
  )

tpi_index <-qgis_function("gdal:tpitopographicpositionindex")
tpi_index(
  INPUT = stack_raster[["dem"]],
  BAND = 1 ,
  OUTPUT = sprintf("%s/%s_tpi.tif", name_output, name_community)
)

# 3. downscaling precipitacion y humedad ----------------------------------
precipation <- rast("terraclimate/terraclimate_pr.tif") |> 
  resample(G)

worldclim_pp <- rast("worldclim/worldclim_pp.tif") |> 
  resample(G)

# covariables for downscaling
ndvi <- rast("covariable/huayllapata_ndvi.tif")
slope <- rast("covariable/huayllapata_slope.tif")
aspect <- rast("covariable/huayllapata_aspect.tif")

downscaling <- qgis_function("sagang:gwrforgriddownscaling")
downscaling(
  PREDICTORS =  qgis_list_input(ndvi,slope,aspect),
  REGRESSION =  sprintf("%s/%s_worldclim_pp.tif", name_output, name_community),,
  DEPENDENT = worldclim_pp)

downscaling(
  PREDICTORS =  qgis_list_input(ndvi,slope,aspect),
  REGRESSION =  sprintf("%s/%s_pp.tif", name_output, name_community),,
  DEPENDENT = precipation)

humedad <- rast("terraclimate/terraclimate_soil.tif") |> resample(G)
downscaling <- qgis_function("sagang:gwrforgriddownscaling")
downscaling(
  PREDICTORS = qgis_list_input(ndvi,slope,aspect),
  REGRESSION = sprintf("%s/%s_soil.tif", name_output, name_community),
  DEPENDENT = humedad)

# 4. New stack for modeling -----------------------------------------------
list_covab <- list.files(
  path = name_output,
  pattern = "*.tif$",
  full.names = TRUE) 

stack_covab <- list_covab|> rast()
names(stack_covab) <- gsub('huayllapata_','',names(stack_covab))

db_covariables <- rast(list(stack_raster,stack_covab))
if(!dir.exists("stack_covariables")){dir.create("stack_covariables")}
writeRaster(db_covariables, sprintf("stack_covariables/stack_covariables_%s.tif", name_community))