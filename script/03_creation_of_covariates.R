library(qgisprocess)
library(terra)

# Path of Bands
PATH_G   <- 'Primera Salida/Huayllapata/huayllapata_G.tif'
PATH_R   <- 'Primera Salida/Huayllapata/huayllapata_R.tif'
PATH_RE  <- 'Primera Salida/Huayllapata/huayllapata_RE.tif'
PATH_NIR <- 'Primera Salida/Huayllapata/huayllapata_NIR.tif'
PATH_TIR   <- 'Primera Salida/Huayllapata/huayllapata_T.tif'


# Reading data of the multispectral and thermal image drone
G   <- rast(PATH_G)
R   <- rast(PATH_R)
RE  <- rast(PATH_RE)
NIR <- rast(PATH_NIR)
TIR <- rast(PATH_TIR)

# Alignment of rasters based on the green band
R   <- resample(R,G)
RE  <- resample(RE,G)
NIR <- resample(NIR,G)
TIR <- resample(TIR[[1]],G)

# New stack raster with 5 bands 
stack_raster <- rast(c(G,R,RE,NIR,TIR))

# Remove bands of list
rm(G);rm(R);rm(RE);rm(NIR);rm(TIR)

# 1. Environmental variables ----------------------------------------------


# 2. Topographic variables ------------------------------------------------

