library(plumber2)
library(mirai)
library(promises)

daemons(4L, dispatcher = TRUE)

model_cache <- memoise::cache_filesystem(
  here::here(".rcache")
)

tasks <- new.env()

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
  invisible(TRUE)
}

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
function(response) {
  id <- uuid::UUIDgenerate(n = 1)
  location <- paste0("/train/", id, "/status")
  task <- list(
    id = id,
    created = Sys.time(),
    status = "queued",
    task = NULL,
    error = NULL
  )
  tasks[[id]] <- task
  tasks[[id]][["task"]] <- mirai(
    {
      result <- model_train(palmerpenguins::penguins)
      result
    },
    model_train = model_train
  )
  tasks[[id]][["status"]] <- "running"
  response$status <- 202L
  response$set_header("Location", location)
  response$set_header("Retry-After", 5)
  response$body <- list(
    message = "Task submitted."
  )
  response$Next
}

#* Query status of model training run.
#* @get /train/<id>/status
function(id, response) {
  task_exists_ind <- id %in% names(tasks)
  if (!task_exists_ind) {
    response$status <- 404L
    response$body <- list(message = paste0("Task ID ", id, " not found."))
    return(response$Next)
  }
  task <- tasks[[id]]
  if (task$status == "running" & unresolved(task$task)) {
    out <- list(
      id = task$id,
      created = task$created,
      status = task$status,
    )
    response$status <- 200L
    response$body <- out
    return(response$Next)
  }
  if (
    task$status == "running" &
      !unresolved(task$task) &
      is_mirai_error(task$task$data)
  ) {
    task$status <- "failed"
    task$error <- task$task$data
    tasks[[id]] <- task
    out <- list(
      id = task$id,
      created = task$created,
      status = task$status,
      error = task$error |> as.character()
    )
    response$status <- 200L
    response$body <- out
    return(response$Next)
  }
  if (
    task$status == "running" &
      !unresolved(task$task) &
      !is_mirai_error(task$task$data)
  ) {
    task$status <- "completed"
    task$result_url <- paste0("/train/", id, "/result")
    tasks[[id]] <- task
    memoise::forget(model_load_memoised)
    out <- list(
      id = id,
      created = task$created,
      status = task$status,
      result_url = task$result_url
    )
    response$status <- 200L
    response$body <- out
    return(response$Next)
  }
  if (task$status == "cancelled") {
    out <- list(
      id = task$id,
      created = task$created,
      status = task$status,
      error = task$error |> as.character()
    )
    response$status <- 200L
    response$body <- out
    return(response$Next)
  }
}

#* Get the result of the training run
#* @get /train/<id>/result
function(id, response) {
  task_exists_ind <- id %in% names(tasks)
  if (!task_exists_ind) {
    response$status <- 404L
    response$body <- jsonlite::toJSON(
      list(message = paste0("Task ID ", id, " not found."))
    )
    return(response$Next)
  }
  task <- tasks[[id]]
  out <- list(
    id = task$id,
    created = task$created,
    result = task$task$data
  )
  response$status <- 200L
  response$body <- out
  return(response$Next)
}

#* Cancel a training run.
#* @delete /train/<id>
function(id, response) {
  task_exists_ind <- id %in% names(tasks)
  if (!task_exists_ind) {
    response$status <- 404L
    response$body <- jsonlite::toJSON(
      list(message = paste0("Task ID ", id, " not found."))
    )
    return(response$Next)
  }
  task <- tasks[[id]]
  stop_mirai(task$task)
  task$status <- "cancelled"
  tasks[[id]] <- task
  out <- list(
    id = task$id,
    created = task$created,
    status = task$status
  )
  response$status <- 200L
  response$body <- out
  return(response$Next)
}

#* Predict using ML model.
#* @post /predict
function(body) {
  data <- body$data
  model_predict(
    model = model_load_memoised(),
    data = data
  )
}
