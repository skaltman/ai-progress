# Read in SOTA data from Google Sheets; write out to rds

# Author: Sara Altman
# Version: 2020-03-07

# Libraries
library(tidyverse)
library(googlesheets4)

# Parameters
sheet_key <- "1zUJ9PhhdUoFSxZMXbYp9EDSTqRKssIysRsofs9FrBA4"
ws <- "sota_cleaned.csv"
file_out_nested <- here::here("data/sota/sota_nested.rds")
file_out_unnested <- here::here("data/sota/sota.rds")
file_out_unfiltered <- here::here("data/sota/sota_unfiltered.rds")
file_out_descriptions <- here::here("data/sota/sota_task_descriptions.rds")

# Columns to remove from cleaned data
sota_remove_cols <-
  vars(
    -metrics,
    -description,
    -source_link,
    -synonyms,
    -model_links,
    -paper_url,
    -first_metric_result,
    -contains("first_paper"),
    -contains("last_paper")
  )

# Metrics that are minimized, not maximized
minimize_metrics <-
  c(
    "MAE",
    "MSE",
    "MAE @ 12 step",
    "NME",
    "RMSE",
    "RMSE@80%Train",
    "RMS",
    "Viewpoint I AEPE",
    "rect mask l2 err",
    "mse (10^-3)",
    "ERR@20",
    "free-form mask l1 err	1",
    "free-form mask l2 err",
    "free-form mask l1 err",
    "Search Time (GPU days)",
    "Cumulative regret",
    "Number of params",
    "FID"
  )

# Fix a particular metric
# The original was a Pearson correlation between -100 and 100 instead of -1 and 1
FIX_INDEX <- 413
FIX_MULTIPLIER <- .001
metrics_to_rescale <-
  c(
    "Accuracy",
    "Pearson Correlation",
    "Top-1 Error Rate"
  )
#===============================================================================

separate_values <- function(x) {
  str_remove_all(x, pattern = "[\\'\\[\\]\\{\\}]") %>%
    str_split(pattern = ", ")
}

metrics_tibble <- function(metrics) {
  tibble(
    metric = str_extract(metrics, ".*(?=: )"),
    value = str_extract(metrics, "(?<=: ).*")
  )
}

rescale_metric <- function(name, value) {
  case_when(
    name %in% metrics_to_rescale & value > 1 & value < 100   ~ value / 100,
    name %in% metrics_to_rescale & value > 1 & value <= 1000 ~ value / 1000,
    TRUE                                                     ~ value
  )
}

clean_metrics <- function(metric_name, metric_result) {
  tibble::tibble(metric_result) %>%
    mutate(
      multiplier = if_else(str_detect(metric_result, "B$"), 1e9, 1),
      metric_result =
        (str_remove_all(metric_result, "[^\\d\\.]") %>%
        na_if("") %>%
        as.double()) * multiplier,
      metric_result = rescale_metric(metric_name, metric_result)
    ) %>%
    pull(metric_result)
}

sota_nested <-
  sheet_key %>%
  sheets_read(sheet = ws) %>%
  select(-...1) %>%
  mutate_at(vars(categories, metrics), separate_values) %>%
  mutate(
    metrics = map(metrics, metrics_tibble),
    metric_name = map(metric_name, as.character),
    metric_result = map(metric_result, as.character)
  ) %>%
  write_rds(file_out_nested)

sota_unfiltered <-
  sota_nested %>%
  select_at(sota_remove_cols) %>%
  unnest(
    cols = c(metric_name, metric_result),
    keep_empty = TRUE
  ) %>%
  group_by(benchmark_id, metric_name) %>%
  mutate(
    metric_result = clean_metrics(metric_name, metric_result),
    minimize_metric =
      str_detect(metric_name, "([Ee]rror)|(AEPE)|(MPJPE)") |
      metric_name %in% minimize_metrics,
    metric_standard =
      if_else(
        minimize_metric,
        metric_result * -1,
        metric_result
      )
  ) %>%
  ungroup() %>%
  write_rds(file_out_unfiltered)

sota_unfiltered %>%
  drop_na(paper_date, metric_name, metric_result) %>% # Removes 1,488 - 940 = 548 rows
  group_by(benchmark_id, metric_name, paper_date) %>%
  filter(near(metric_standard, max(metric_standard, na.rm = TRUE))) %>% # Removes 940 - 739 = 201 rows
  top_n(n = 1, wt = index) %>% # There are five rows where the metric_standards are the exact same. Arbitrary take the first.
  ungroup() %>%
  mutate(
    percent_change =
      (metric_standard - first(metric_standard, order_by = paper_date)) /
      abs(first(metric_standard, order_by = paper_date)) * 100
  ) %>%
  ungroup() %>%
  write_rds(file_out_unnested)

sota_nested %>%
  distinct(task, description) %>%
  write_rds(file_out_descriptions)

