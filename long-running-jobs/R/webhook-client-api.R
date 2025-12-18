library(plumber2)
library(httr2)

#* Receive webhook callback from training API.
#* @post /callback
function(body, response) {
  id <- body$id
  status <- body$status
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  message(sprintf("[%s] Task %s: %s", timestamp, id, status))

  response$status <- 200L
  response$body <- list(received = TRUE)
  return(response$Next)
}

#* Initiate a training request to the webhook API.
#* @post /train
function(body, response) {
  webhook_api_url <- body$webhook_api_url
  if (is.null(webhook_api_url)) {
    webhook_api_url <- "http://webhook-pattern-api:8005"
  }

  client_host <- body$client_host
  if (is.null(client_host)) {
    client_host <- "http://webhook-client-api:8006"
  }

  callback_url <- paste0(client_host, "/callback")

  result <- tryCatch(
    {
      resp <- request(paste0(webhook_api_url, "/train")) |>
        req_body_json(list(callback_url = callback_url)) |>
        req_headers("Content-Type" = "application/json") |>
        req_perform()

      response$status <- resp$status_code
      response$body <- resp_body_json(resp)
      response$Next
    },
    error = function(e) {
      response$status <- 500L
      response$body <- list(error = e$message)
      response$Next
    }
  )

  return(result)
}
