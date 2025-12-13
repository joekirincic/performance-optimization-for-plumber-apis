# Load OpenTelemetry packages for automatic tracing
# mirai automatically creates spans when these packages are loaded
library(otel)
library(otelsdk)

library(plumber2)
library(mirai)
library(promises)

mirai::daemons(6L, dispatcher = TRUE)

mirai::everywhere(
  {
    con <<- DBI::dbConnect(
      RPostgres::Postgres(),
      dbname = db_name,
      host = db_host,
      port = db_port,
      user = db_user,
      password = db_password
    )
  },
  db_name = Sys.getenv("DB_NAME"),
  db_host = Sys.getenv("DB_HOST"),
  db_port = Sys.getenv("DB_PORT"),
  db_user = Sys.getenv("DB_USER"),
  db_password = Sys.getenv("DB_PASSWORD")
)

query_penguins <- function(con, n) {
  spn <- otel::start_local_active_span("query_penguins")
  on.exit(otel::end_span(spn))
  qry <- glue::glue("SELECT * FROM penguins LIMIT {n}")
  out <- DBI::dbGetQuery(con, qry)
  out
}

#* Get results from a DB.
#* @get /penguins
#* @query n:int
#* @async
function(query) {
  result <- query_penguins(con, query$n)
  result
}
