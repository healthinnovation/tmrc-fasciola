library(tidyverse)
library(qgisprocess)
library(terra)
library(sf)
library(stars)
library(randomForest)
library(caret)

path <- "output/huaccaycancha_stack.tif"
name <- gsub("output/|_stack.tif","",path)
img_sat <- rast(path)

# Sample data
samples <- st_read(
  dsn = "Primera Salida/Huayccaycancha/muestras.gpkg",
  as_tibble = T) %>%
  dplyr::select(clase) |> 
  drop_na()

# Extract data 

df <- terra::extract(img_sat, samples, df = T) %>%
  as_tibble() %>%
  left_join(
    dplyr::mutate(samples, ID = 1:n()),
    by = "ID"
  ) %>%
  dplyr::select(-geometry,-ID) %>%
  dplyr::rename(id.cls = clase) %>%
  dplyr::mutate(id.cls = factor(id.cls)) %>%
  drop_na()

# Select training and testing data
set.seed(2023)
random.sample <- createDataPartition(y = df$id.cls, p = 0.80, list = FALSE)
training <- df[random.sample, ]
testing <- df[-random.sample, ]

# Building of model
# Control parameters for train
fitControl <- trainControl(method = "cv", number = 3)

# Train model
rf.model <- train(
  id.cls ~ nir + green  + red + redge + tir,
  data = training,
  method = "parRF",
  ntree = 500,
  na.action = na.exclude,
  trControl = fitControl
)

# plot(varImp(rf.model))

# Predicted
rf.prdct <- predict(rf.model, newdata = dplyr::select(testing, -id.cls))

# build confusion matrix
rf.con.mtx <- confusionMatrix(
  data = rf.prdct, testing$id.cls, dnn = c("original", "predicted")
)

# calculate kappa value
rf.kappa <- kappa(rf.con.mtx$table)

# predict raster dataset
rf.result.raster <- terra::predict(img_sat, rf.model, na.rm = TRUE)

# Filter by median 9x9 
filter_median <- qgis_function(algorithm = "grass7:r.neighbors")
rf.result.raster <- filter_median(input = rf.result.raster,method = 2,size = 9) 
rf <- rf.result.raster %>% qgis_as_terra()
writeRaster(rf,sprintf('output/classified_%s.tif',name),overwrite = T)