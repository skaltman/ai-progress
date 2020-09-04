# Read in, tidy, and write out original SOTA data
# Source: https://paperswithcode.com/about

# Author: Sara Altman
# Version: 2020-05-01

# Libraries
library(tidyverse)
library(lubridate)

# Parameters
  # URL for original data
url_data <- "https://paperswithcode.com/media/about/evaluation-tables.json.gz"
  # Output file
file_out <- here::here("data/sota/sota.rds")
  # Output file for paper counts
file_group_counts <- here::here("data/sota/groups.rds")
  # File with metrics to minimize, not maximize
file_metric_patterns <- here::here("data/sota/metric_patterns.yml")
  # Directory to download original data
dir_data <- here::here("data/sota")
  # Quantile cutoff for outliers
QUANTILE_CUTOFF <- 0.975
#===============================================================================

dest <- fs::path(dir_data, "evaluation_tables.json")
download.file(url_data, destfile = dest)

original_json <-
  dest %>%
  jsonlite::read_json()

patterns_all <-
  yaml::read_yaml(file_metric_patterns) %>%
  map(str_c, collapse = "|")

patterns_error <- patterns_all$error_patterns
patterns_accuracy <- patterns_all$accuracy_patterns
patterns_minimize <-
  str_c(patterns_all$minimize_patterns, patterns_error, sep = "|")

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
    TRUE                            ~ as.double(metric)
  )
}

cumulative_best_result <- function(value, name) {
  minimize <- str_detect(name, patterns_minimize)

  if_else( # Only include results that are better than the previous ones
    minimize,
    value == cummin(value),
    value == cummax(value)
  )
}

paper_best_result <- function(value, name) {
  minimize <- str_detect(name, patterns_minimize)
  accuracy <- str_detect(name, patterns_accuracy)

  if_else(
    minimize | accuracy,
    value == min(value),
    value  == max(value)
  )
}

accuracy_to_error <- function(value, name) {
  accuracy <- str_detect(name, patterns_accuracy)

  case_when(
    !accuracy                            ~ value,
    accuracy & all(value <= 1)           ~ 100 - (value * 100),
    accuracy & all(value <= 100)         ~ 100 - value,
    TRUE                                 ~ NA_real_
  )
}

# Log error metrics
# (including accuracy metrics that were previously turned into error metrics)
# Non-vectorized to avoid warnings about NaNs
log_metrics <- function(value, name) {
  error <- str_detect(name, patterns_error)
  accuracy <- str_detect(name, patterns_accuracy)

  if (error | accuracy) {
    log(value)
  } else {
    value
  }
}

# All results, but cleaned up and rectangled
sota_all <-
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
  mutate(
    paper_date = lubridate::as_date(paper_date),
    multiplier = str_extract(metric_result_original, "[KkMmBb\\%]$"),
    metric_result = clean_metrics(metric_result_original, multiplier),
    metric_name = str_to_lower(metric_name),
    across(where(is.character), ~ na_if(., ""))
  ) %>%
  unite(col = "group", task, dataset, metric_name, remove = FALSE)

# Filter to include only SOTA results, and change accuracy metrics to error metrics
v <-
  sota_all %>%
  group_by(group) %>%
  arrange(paper_date) %>%
  # Only include the SOTA results
  filter(cumulative_best_result(metric_result, metric_name)) %>%
  rowwise() %>%
  mutate(
    metric_result =
      accuracy_to_error(metric_result, metric_name) %>%
      log_metrics(metric_name)
  ) %>%
  ungroup() %>%
  group_by(group, paper_date) %>%
  # Only include one (the best) result per paper
  filter(paper_best_result(metric_result, metric_name)) %>%
  group_by(group, metric_result) %>%
  # Occasionally there are papers with identical results. Only include one.
  slice_min(order_by = paper_date, with_ties = FALSE) %>%
  ungroup() %>%
  select(-datasets, -sota, -rows, -multiplier, -metric_result_original) %>%
  arrange(task, dataset, paper_date)

sota_all <-
  v %>%
  drop_na(paper_date, metric_result) %>%
  group_by(group) %>%
  mutate(
    n_results = n(),
    percent_change =
      abs((metric_result - lag(metric_result, order_by = paper_date)) /
            lag(metric_result, order_by = paper_date)),
    days_since_first_paper = (min(paper_date) %--% paper_date) / days(1)
  ) %>%
  ungroup()

sota_all %>%
  drop_na(percent_change) %>%
  filter(
    percent_change < Inf,
    task != "Atari Games"
  ) %>%
  group_by(year(paper_date)) %>%
  filter(percent_change < quantile(percent_change, QUANTILE_CUTOFF)) %>%
  ungroup() %>%
  write_rds(file_out)
