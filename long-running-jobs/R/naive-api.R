library(plumber2)
library(mirai)
library(promises)

mirai::daemons(4L, dispatcher = TRUE)

model_train <- function(data) {
  data <- tidyr::drop_na(data)
  model <- lm(
    body_mass_g ~ species +
      island +
      bill_length_mm +
      bill_depth_mm +
      flipper_length_mm +
      sex +
      year,
    data = data
  )
  saveRDS(model, file = here::here("model.rds"))
  TRUE
}

model_cache <- memoise::cache_filesystem(
  here::here(".rcache")
)

model_load <- function() {
  readRDS(file = here::here("model.rds"))
}

model_load_memoised <- memoise::memoise(model_load, cache = model_cache)

model_predict <- function(model, data) {
  model <- model_load_memoised()
  predict(model, newdata = data)
}

#* Train ML model.
#* @post /train
#* @async
function() {
  payload <- model_train(palmerpenguins::penguins)
  payload
}
#* @then
function(server, response) {
  memoise::forget(model_load_memoised)
  model_load_memoised()
  response$body <- list(
    message = "Task submitted."
  )
  Next
}

#* Predict using ML model.
#* @post /predict
function(body) {
  data <- body$data
  print(data)
  print(
    model_load_memoised()
  )
  model_predict(
    model = model_load_memoised(),
    data = data
  )
}
