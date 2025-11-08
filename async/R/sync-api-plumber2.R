library(plumber2)

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("DB_NAME"),
  host = Sys.getenv("DB_HOST"),
  port = Sys.getenv("DB_PORT"),
  user = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD")
)

query_penguins <- function(con, n) {
  qry <- glue::glue("SELECT * FROM penguins LIMIT {n}")
  out <- DBI::dbGetQuery(con, qry)
}

#* Get results from a DB.
#* @get /penguins
#* @query n:int
function(query) {
  out <- query_penguins(con, query$n)
  out
}
