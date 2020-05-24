# Read in, tidy, and write out original SOTA data
# Source: https://paperswithcode.com/about

# Author: Sara Altman
# Version: 2020-05-01

# Libraries
library(tidyverse)

# Parameters
  # URL for original data
url_data <- "https://paperswithcode.com/media/about/evaluation-tables.json.gz"
  # Output file
file_out <- here::here("data/sota/sota.rds")
  # Directory to download original data
dir_data <- here::here("data/sota")
#===============================================================================

dest <- fs::path(dir_data, "evaluation_tables.json")
download.file(url_data, destfile = dest)

original_json <-
  dest %>%
  jsonlite::read_json()

clean_metrics <- function(metric, multiplier) {
  metric <-
    metric %>%
    str_trim(side = "both") %>%
    str_remove_all("[KkMmBb\\%&]") %>%
    str_remove_all("\\(.*\\)") %>%
    str_remove_all("\\*") %>%
    str_replace(",", "\\.") %>%
    str_replace("([^0-9]$)|([:alpha:])|(.*\\/.*)|:", NA_character_) %>%
    na_if("")

  case_when(
    multiplier == "k"               ~ as.double(metric) * 1e3,
    multiplier == "m"               ~ as.double(metric) * 1e6,
    multiplier == "b"               ~ as.double(metric) * 1e9,
    multiplier == "%"               ~ as.double(metric) / 100,
    TRUE                            ~ as.double(metric)
  )
}

sota <-
  tibble(
    task = map_chr(original_json, "task"),
    categories = map(original_json, ~ .$categories %>% unlist()),
    datasets = map(original_json, "datasets")
  ) %>%
  unnest(datasets) %>% # drops tasks with no listed datasets
  hoist(datasets, dataset = "dataset", sota = "sota") %>%
  hoist(sota, rows = "rows") %>%
  unnest(rows, keep_empty = TRUE) %>%
  hoist(
    rows,
    paper_title = "paper_title",
    paper_date = "paper_date",
    model_name = "model_name",
    metrics = "metrics"
  ) %>%
  unnest_longer(
    col = metrics,
    values_to = "metric_result_original",
    indices_to = "metric_name"
  ) %>%
  unnest(cols = categories) %>%
  rename(category = categories) %>%
  mutate(
    paper_date = lubridate::as_date(paper_date),
    multiplier = str_extract(metric_result_original, "[KkMmBb\\%]$"),
    metric_result = clean_metrics(metric_result_original, multiplier)
  ) %>%
  select(-datasets, -sota, -rows, -multiplier, -metric_result_original) %>%
  mutate(across(where(is.character), ~ na_if(., ""))) %>%
  write_rds(file_out)

