library(qgisprocess)
library(terra)

# 1. Defined parameters ---------------------------------------------------
name_output <- "covariable"
name_community <- "Ohuay"

# 2. Reading spatial data -------------------------------------------------
# Path of Bands
PATH_G <- "Primera Salida/Ohuay/Ohuay_G.tif"
PATH_R <- "Primera Salida/Ohuay/Ohuay_R.tif"
PATH_RE <- "Primera Salida/Ohuay/Ohuay_RE.tif"
PATH_NIR <- "Primera Salida/Ohuay/Ohuay_NIR.tif"
PATH_TIR <- "Primera Salida/Ohuay/Ohuay_T.tif"
PATH_DEM <- "Primera Salida/Ohuay/Ohuay_dem.tif"

# Reading data of the multispectral and thermal image drone
G <- rast(PATH_G)
R <- rast(PATH_R)
RE <- rast(PATH_RE)
NIR <- rast(PATH_NIR)
TIR <- rast(PATH_TIR)
DEM <- rast(PATH_DEM)

# Alignment of rasters based on the green band
R <- resample(R, G)
RE <- resample(RE, G)
NIR <- resample(NIR, G)
TIR <- resample(TIR[[1]], G)
DEM <- rast(DEM, G)

# New stack raster with 5 bands
stack_raster <- rast(list(G, R, RE, NIR, TIR, DEM))
names(stack_raster) <- c("green", "red", "redge", "nir", "tir", "dem")

# Remove bands of list
rm(G);rm(R);rm(RE);rm(NIR);rm(TIR)
if(!dir.exists("output")){dir.create("output")}
writeRaster(stack_raster, sprintf("output/stack_%s.tif", name_community))

# 1. Environmental variables ----------------------------------------------
if(!dir.exists(name_output)){dir.create(name_output)}
veg_index <- qgis_function("sagang:vegetationindexslopebased")
veg_index(
  RED = stack_raster[["red"]],
  NIR = stack_raster[["nir"]],
  SAVI = sprintf("%s/%s_savi.tif", name_output, name_community),
  NDVI = sprintf("%s/%s_ndvi.tif", name_output, name_community)
)

# 2. Topographic variables ------------------------------------------------
topo_index <- qgis_function("sagang:basicterrainanalysis")
topo_index(
  ELEVATION = DEM,
  SHADE = sprintf("%s/%s_shade.tif", name_output, name_community),
  SLOPE = sprintf("%s/%s_slope.tif", name_output, name_community),
  ASPECT = sprintf("%s/%s_aspect.tif", name_output, name_community),
  WETNESS = sprintf("%s/%s_wetness.tif", name_output, name_community),
  VALL_DEPTH = sprintf("%s/%s_vall_depth.tif", name_output, name_community)
)

# 3. New stack for modeling -----------------------------------------------
list_covab <- list.files(path = name_output, pattern = "*.tif$", full.names = TRUE)
stack_covab <- rast(list_covab)
file.remove(sprintf("output/stack_%s.tif", name_community))
writeRaster(stack_covab, sprintf("output/stack_covab_%s.tif", name_community))