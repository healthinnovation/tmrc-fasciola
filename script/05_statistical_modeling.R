library(tidyverse)
library(sf)
library(terra)
library(h3jsr)
library(qgisprocess)
library(tidymodels)

# 0. Community selected --------------------------------------------------
region <- st_read(
  dsn = "vector/gpkg/sdb_cusco.gpkg",
  layer = "huayllapata")

hex <- region |> 
  polygon_to_cells(res = 12, simple = FALSE) 

region_hex <- cell_to_polygon(hex$h3_addresses, simple = FALSE)

# 1. Houses with fasciola -------------------------------------------------
houses <- readxl::read_xlsx("xlsx/hogar_fasciola_cusco.xlsx") 
sf_houses <- houses |> 
  st_as_sf(coords = c('h_gps_longitude','h_gps_latitude'),crs = 4326) |> 
  filter(p_comunidad %in% "Huayllapata")

# 2. Count points in polygons ---------------------------------------------
qgis_count <- qgis_function("native:countpointsinpolygon")
qgis_count(
  POLYGONS = region_hex,
  POINTS = sf_houses,
  FIELD = "target",
  OUTPUT = qgis_tmp_vector()) |> 
  qgis_extract_output("OUTPUT") |> 
  st_read() |> 
  vect() -> region_hex

# 3. Extracting the covariables values ------------------------------------
stack_cov <- rast("stack_covariables/stack_covariables_huayllapata.tif")
database <- extract(stack_cov,region_hex, f = "mean", na.rm = TRUE,bind = TRUE) 
normalize <- function(x) {(x - min(x)) / (max(x) - min(x))}

database_sf <- database |> 
  st_as_sf() %>%
  mutate(across(where(is.numeric), ~ replace(., is.infinite(.) | is.nan(.), 0))) |> 
  mutate(
    target = case_when(target > 1 ~ 1 ,.default = target),
    target = as.factor(target)) |> 
  mutate(across(green:wetness, normalize))

glimpse(database_sf)


# 4. Logist regression ----------------------------------------------------
set.seed(2024)
fasciola_split <- initial_split(database_sf,prop = 0.80,strata = target)

# Create training data
fasciola_train <- fasciola_split |> training()

# Create testing data
fasciola_test <- fasciola_split |> testing()

# Number of rows in train and test dataset
nrow(fasciola_train)
nrow(fasciola_test)


logistic_spec <- logistic_reg() %>%
  set_engine("glm") 

logistic_wf <- workflow() %>%
  add_model(logistic_spec) %>%
  add_formula(
      target ~ temp  +
      shade + soil + wetness + rvi + nir + rvi + vall_depth )

logistic_fit <- fit(logistic_wf, data = fasciola_train)
tidy(logistic_fit) |> View()
predicciones <- predict(logistic_fit, database_sf, type = "prob")
results <- bind_cols(database_sf, predicciones)

ggplot() + 
  geom_sf(data = results, aes(fill = .pred_1), col = NA) + 
  scale_fill_viridis_c(option = "inferno",direction = -1) + 
  theme_minimal()
