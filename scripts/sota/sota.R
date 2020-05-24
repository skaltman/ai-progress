# Read in, tidy, and write out original SOTA data
# Source: https://paperswithcode.com/

# Author: Sara Altman
# Version: 2020-05-01

# Libraries
library(tidyverse)

# Parameters
file_in <- here::here("data/sota/evaluation-tables.json")
file_out <- here::here("data/sota/sota.rds")
#===============================================================================

# TODO: DEAL WITH THE DASHES.
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

original_json <-
  file_in %>%
  jsonlite::read_json()

sota <-
  tibble(
    task = map_chr(original_json, "task"),
    categories = map(original_json, "categories"),
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
  mutate(
    paper_date = lubridate::as_date(paper_date),
    multiplier = str_extract(metric_result_original, "[KkMmBb\\%]$"),
    metric_result = clean_metrics(metric_result_original, multiplier)
  ) %>%
  select(-datasets, -sota, -rows, -multiplier, -metric_result_original) %>%
  write_rds(file_out)

