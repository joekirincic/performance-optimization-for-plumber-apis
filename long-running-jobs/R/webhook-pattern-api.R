library(plumber2)
library(mirai)
library(promises)
library(httr2)

daemons(4L, dispatcher = TRUE)

tasks <- new.env()

model_cache <- memoise::cache_filesystem(
  here::here(".rcache")
)

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
function(body, response) {
  callback_url <- body$callback_url
  if (is.null(callback_url)) {
    response$status <- 400L
    return(list(error = "callback_url is required"))
  }

  id <- uuid::UUIDgenerate(n = 1)
  created <- Sys.time()

  task <- list(
    id = id,
    created = created,
    status = "queued",
    task = NULL
  )

  tasks[[id]] <- task

  task$task <- mirai(
    {
      library(httr2)

      result <- tryCatch(
        {
          model_train(palmerpenguins::penguins)
          list(status = "completed", result = TRUE)
        },
        error = function(e) {
          list(status = "failed", error = as.character(e))
        }
      )

      payload <- list(
        id = id,
        created = created,
        status = result$status
      )
      if (result$status == "completed") {
        payload$result <- result$result
      } else {
        payload$error <- result$error
      }

      # Send webhook with retry logic
      tryCatch(
        {
          resp <- request(callback_url) |>
            req_body_json(payload) |>
            req_headers("Content-Type" = "application/json") |>
            req_retry(max_tries = 3, backoff = ~2) |>
            req_perform()

          out <- list(
            status_code = resp$status_code,
            body = resp_body_json(resp)
          )
          out
        },
        error = function(e) {
          message("Webhook delivery failed: ", e$message)
        }
      )

      result$status
    },
    id = id,
    created = created,
    callback_url = callback_url,
    model_train = model_train
  )

  task$status <- "running"
  tasks[[id]] <- task
  out <- list(
    id = id,
    created = created,
    status = "queued",
    message = "Training job submitted. Results will be sent to callback URL."
  )

  response$status <- 202L
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
