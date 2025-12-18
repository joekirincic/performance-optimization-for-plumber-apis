library(optparse)

app_options <- list(
  make_option(
    opt_str = "--app",
    type = "character",
    help = "Which app to run"
  )
)

arguments <- parse_args(
  OptionParser(option_list = app_options)
)

switch(
  arguments$app,
  naive_api = {
    app <- plumber2::api("naive-api.R", host = "0.0.0.0", port = 8003L)
    plumber2::api_run(app)
  },
  polling_pattern = {
    app <- plumber2::api(
      "polling-pattern-api.R",
      host = "0.0.0.0",
      port = 8004L
    )
    plumber2::api_run(app)
  },
  webhook_pattern = {
    app <- plumber2::api(
      "webhook-pattern-api.R",
      host = "0.0.0.0",
      port = 8005L
    )
    plumber2::api_run(app)
  },
  webhook_client = {
    app <- plumber2::api(
      "webhook-client-api.R",
      host = "0.0.0.0",
      port = 8006L
    )
    plumber2::api_run(app)
  }
)
