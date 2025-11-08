library(tidyverse)

df <- read_csv(
  file = list.files("async/load-test-results", full.names = TRUE),
  id = "load_test"
)

cmp <- df |>
  mutate(
    timestamp = as_datetime(timestamp),
    load_test = fs::path_file(load_test) |>
      str_remove_all(pattern = "\\.csv|load-test_")
  ) |>
  summarize(
    min_response_time_ms = min(response_time, na.rm = TRUE) |>
      round(digits = 2),
    med_response_time_ms = median(response_time, na.rm = TRUE) |>
      round(digits = 2),
    max_response_time_ms = max(response_time, na.rm = TRUE) |>
      round(digits = 2),
    total_seconds = time_length(
      max(timestamp) - min(timestamp),
      unit = "second"
    ) |>
      round(digits = 2),
    total_requests = n(),
    rps = (total_requests / total_seconds) |> round(digits = 2),
    .by = load_test
  )

cmp |>
  knitr::kable()
