library(tidyverse)
library(sf)
library(terra)
library(h3jsr)
library(qgisprocess)
library(tidymodels)
library(MASS)
library(cptcity)
library(basemaps)
library(extrafont)
library(poissonreg)

# 0. Community selected --------------------------------------------------
path_xlsx <- "xlsx/hogar_fasciola_cusco.xlsx"
path_gpkg <- "vector/gpkg/sdb_cusco.gpkg"
community <- "huayllapata"

region <- st_read(dsn = path_gpkg, layer = community)

# Hexagrid H3
hex <- region %>% polygon_to_cells(res = 12, simple = FALSE) 
region_hex <- cell_to_polygon(hex$h3_addresses, simple = FALSE)

# 1. Houses with fasciola -------------------------------------------------
houses <- readxl::read_xlsx(path_xlsx) %>% mutate(p_comunidad = str_to_lower(p_comunidad))
sf_houses <- houses %>% 
  st_as_sf(coords = c('h_gps_longitude','h_gps_latitude'),crs = 4326) %>% 
  filter(p_comunidad %in% community) %>% 
  dplyr::select(h_fecha,humanos_pos,humanos_nropos) %>% 
  st_as_sf()

# Conteo de nro de personas
sf_houses$humanos_nropos %>% sum()

# 2. Count points in polygons ---------------------------------------------
qgis_count <- qgis_function("native:joinattributesbylocation")
region_hex_cases <- qgis_count(
  INPUT = region_hex,
  PREDICATE = 0,
  JOIN = sf_houses,
  OUTPUT = qgis_tmp_vector()
  ) %>% 
  qgis_extract_output("OUTPUT") %>% 
  st_read() %>% 
  dplyr::select(humanos_pos) %>% 
  rename(target = humanos_pos) %>% 
  mutate_all(~replace(., is.na(.), 0))

# 3. Extracting the covariables values ------------------------------------
stack_cov <- rast("stack_covariables/stack_covariables_huayllapata.tif")
database <- extract(stack_cov, region_hex_cases, f = "mean", na.rm = TRUE, bind = TRUE) 
normalize <- function(x) {(x - min(x)) / (max(x) - min(x))}
database_sf <- database %>% 
  st_as_sf() %>%
  mutate(across(green:wetness, normalize)) %>%
  mutate_all(~replace(., is.na(.), 0))

glimpse(database_sf)

# 4. Logist regression ----------------------------------------------------
set.seed(2024)
db4model <- database_sf %>% st_drop_geometry()

fasciola_split <- db4model %>%
  initial_split(prop = 0.80,strata = target)

# Create training data
fasciola_train <- fasciola_split %>% training()

# Create testing data
fasciola_test <- fasciola_split %>% testing()

# Number of rows in train and test dataset
nrow(fasciola_train)
nrow(fasciola_test)

# Definir el modelo de regresión logística con parsnip
modelo_logit <- logistic_reg() %>%
  set_engine("glm")

# Ajustar el modelo inicial con todas las variables
fasciola_train_logist <- fasciola_train %>% mutate(target = as.factor(target))
fasciola_test_logist <- fasciola_test %>% mutate(target = as.factor(target))

modelo_inicial <- glm(target ~., data = fasciola_train_logist, family = binomial)

# Realizar la selección de variables usando stepAIC
modelo_final_step <- stepAIC(modelo_inicial, direction = "both")
formula <- modelo_final_step[["formula"]]

logistic_spec <- logistic_reg() %>%
  set_engine("glm")
 
logistic_wf <- workflow() %>%
  add_model(logistic_spec) %>%
  add_formula(formula)

# Ajuste del modelo con los datos de entrenamiento usando el workflow
logistic_fit <- logistic_wf %>%
  fit(data = fasciola_train_logist)

# Realizar predicciones en los datos de prueba
logistic_predictions <- logistic_fit %>%
  predict(new_data = fasciola_test_logist, type = "prob") %>%
  bind_cols(fasciola_test)

# Calcular métricas de evaluación
logistic_metrics <- logistic_predictions %>%
  metrics(truth = target, estimate = .pred_1)

# Ver métricas de evaluación
print(logistic_metrics)
tidy(logistic_fit) %>% View()


# Predicción en toda la base de datos espacial
logistic_predictions_spatial <- logistic_fit %>%
  predict(new_data = database_sf, type = "prob") %>%
  bind_cols(database_sf)


# 5. Poisson model --------------------------------------------------------

# Modelo de Poisson inicial con todos los predictores
poisson_model_full <- glm(target ~ ., family = poisson(), data = db4model)

# Realizar la selección de variables usando stepAIC
modelo_final_step <- stepAIC(modelo_inicial, direction = "both")
formula <- modelo_final_step[["call"]] %>% as.formula()

# Crear el modelo binomial
poisson_model <- poisson_reg() %>%
  set_engine("glm")

# Definir el workflow
poisson_workflow <- workflow() %>%
  add_model(poisson_model) %>% 
  add_recipe(recipe = recipe(formula,fasciola_train))

# Entrenar el modelo
poisson_fit <- poisson_workflow %>%
  fit(data = fasciola_train)

# Evaluar el modelo
poisson_predictions <- poisson_fit %>%
  predict(fasciola_test) %>%
  bind_cols(fasciola_test)

# Evalúa el rendimiento (por ejemplo, con métricas de RMSE, MAE, etc.)
metrics <- poisson_predictions %>%
  metrics(truth = target, estimate = .pred)

# Predicción en toda la base de datos espacial
poisson_predictions_spatial <- poisson_fit %>%
  predict(database_sf) %>%
  bind_cols(database_sf)

# 6. Machine learning -----------------------------------------------------
regression_recipe <- recipe(target ~ ., data = fasciola_train)
cv_folds <- vfold_cv(fasciola_train, v = 5)

## Modelo de random forest
rf_model <- rand_forest() %>%
  set_engine("ranger") %>%
  set_mode("regression")

# Flujo de trabajo para random forest
rf_workflow <- workflow() %>%
  add_model(rf_model) %>%
  add_recipe(regression_recipe)

# Evaluar el modelo de Random Forest con validación cruzada
rf_results <- rf_workflow %>%
  fit_resamples(resamples = cv_folds, 
                metrics = metric_set(rmse, rsq),  
                control = control_resamples(save_pred = TRUE))

# Obtener el resumen de los resultados de validación cruzada
# rf_results %>% collect_metrics()

# Ajustar el modelo final en todo el conjunto de entrenamiento
rf_final_fit <- rf_workflow %>%
  last_fit(split = fasciola_split)

# Hacer predicciones en el conjunto de prueba
rf_final_predictions <- rf_final_fit %>%
  collect_predictions()

# Evaluar el rendimiento en el conjunto de prueba
rf_final_metrics <- rf_final_predictions %>%
  metrics(truth = target, estimate = .pred)

## Predicci+on en toda la data
rf_fit_full <- rf_workflow %>%
  fit(data = database_sf)

rf_spatial <- rf_fit_full %>%
  predict(database_sf) %>%
  bind_cols(database_sf)


## Modelo de gradient boosting
gb_model <- boost_tree() %>%
  set_engine("xgboost") %>%
  set_mode("regression")

# Flujo de trabajo para Gradient Boosting
gb_workflow <- workflow() %>%
  add_model(gb_model) %>%
  add_recipe(regression_recipe)

# Evaluar el modelo de Gradient Boosting con validación cruzada
gb_results <- gb_workflow %>%
  fit_resamples(resamples = cv_folds, 
                metrics = metric_set(rmse, rsq),  
                control = control_resamples(save_pred = TRUE))

# Ajustar el modelo final en todo el conjunto de entrenamiento
gb_final_fit <- gb_workflow %>%
  last_fit(split = fasciola_split)

# Hacer predicciones en el conjunto de prueba
gb_final_predictions <- gb_final_fit %>%
  collect_predictions()

# Evaluar el rendimiento en el conjunto de prueba
gb_final_metrics <- gb_final_predictions %>%
  metrics(truth = target, estimate = .pred)

## Predicción en toda la base de datos
# Ajustar el modelo en todo el conjunto de datos
gb_fit_full <- gb_workflow %>%
  fit(data = database_sf)

# Hacer predicciones en todo el conjunto de datos
gb_spatial <- gb_fit_full %>%
  predict(database_sf) %>%
  bind_cols(database_sf)