library(DBI)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("DB_NAME"),
  host = Sys.getenv("DB_HOST"),
  port = Sys.getenv("DB_PORT"),
  user = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD")
)

payload <- palmerpenguins::penguins

dbWithTransaction(
  con,
  {
    if (!dbExistsTable(con, "penguins")) {
      dbWriteTable(
        con,
        name = "penguins",
        value = payload
      )
    } else {
      dbExecute(con, "TRUNCATE TABLE penguins")
      dbWriteTable(
        con,
        name = "penguins",
        value = payload,
        append = TRUE
      )
    }
  }
)
