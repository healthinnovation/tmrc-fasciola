library(rgee)
library(terra)
library(sf)
ee_Initialize(user = "antony.barja@upch.pe",drive = TRUE)


# 1. Study area -----------------------------------------------------------
spatial_data <- "vector/kml/huayllapata.kml"
region <- st_read(spatial_data) |> 
  st_transform(crs = 32718) |> 
  st_buffer(dist = 5000) |> 
  st_bbox() |> 
  st_as_sfc()

region_ee <- region |> sf_as_ee()


# 2. Download climate variables proccesed on GEE --------------------------

terraclimate <- ee$ImageCollection('IDAHO_EPSCOR/TERRACLIMATE') |> 
  ee$ImageCollection() |> 
  ee$ImageCollection$filter(ee$Filter$calendarRange(1958,2023,'year')) |> 
  ee$ImageCollection$filter(ee$Filter$calendarRange(4,4,'month')) |> 
  ee$ImageCollection$mean() |> 
  ee$Image$clip(region_ee)

pp <- terraclimate$select('pr')
soil <- terraclimate$select('soil')

# 3. Raster local  --------------------------------------------------------
ee_as_rast(
  image = pp,
  region = region_ee,
  scale = 4638.3,
  crs = 'epsg:32718',
  dsn = 'input-downscaling/terraclimate_pr.tif')

ee_as_rast(
  image = soil,
  region = region_ee,
  scale = 4638.3,
  crs = 'epsg:32718',
  dsn = 'input-downscaling/terraclimate_soil.tif')
