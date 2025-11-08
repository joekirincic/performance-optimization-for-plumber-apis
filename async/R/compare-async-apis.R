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
    min_response_time = min(response_time, na.rm = TRUE),
    med_response_time = median(response_time, na.rm = TRUE),
    max_response_time = max(response_time, na.rm = TRUE),
    total_seconds = time_length(
      max(timestamp) - min(timestamp),
      unit = "second"
    ),
    total_requests = n(),
    rps = total_requests / total_seconds,
    .by = load_test
  )
