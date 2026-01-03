library(optparse)

app_options <- list(
  make_option(
    opt_str = "--app",
    type = "character",
    help = "Which app to run (sync_plumber2, async_plumber2, or async_plumber)"
  )
)

arguments <- parse_args(
  OptionParser(option_list = app_options)
)

switch(
  arguments$app,
  sync_plumber2 = {
    app <- plumber2::api("sync-api-plumber2.R", host = "0.0.0.0", port = 8000L)
    plumber2::api_run(app)
  },
  async_plumber2 = {
    app <- plumber2::api("async-api-plumber2.R", host = "0.0.0.0", port = 8001L)
    plumber2::api_run(app)
  },
  async_plumber = {
    app <- plumber::plumb("async-api-plumber.R")
    plumber::pr_run(app, "0.0.0.0", port = 8002L)
  },
  async_plumber2_manual = {
    app <- plumber2::api(
      "async-api-plumber2-manual.R",
      host = "0.0.0.0",
      port = 8003L
    )
    plumber2::api_run(app)
  },
)
