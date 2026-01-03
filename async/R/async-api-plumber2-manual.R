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
    query_penguins <<- function(con, n) {
      qry <- glue::glue("SELECT * FROM penguins LIMIT {n}")
      out <- DBI::dbGetQuery(con, qry)
    }
  },
  db_name = Sys.getenv("DB_NAME"),
  db_host = Sys.getenv("DB_HOST"),
  db_port = Sys.getenv("DB_PORT"),
  db_user = Sys.getenv("DB_USER"),
  db_password = Sys.getenv("DB_PASSWORD")
)

#* Get results from a DB.
#* @get /penguins
#* @query n:int
function(query) {
  n <- query$n
  mirai(
    {
      query_penguins(con, n)
    },
    n = n
  ) %...>%
    (function(x) {
      x
    })
}
