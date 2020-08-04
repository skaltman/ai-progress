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
  # Output file for paper counts
file_group_counts <- here::here("data/sota/groups.rds")
  # File with metrics to minimize, not maximize
file_minimize_metrics <- here::here("data/sota/minimize_metrics.yml")
  # Directory to download original data
dir_data <- here::here("data/sota")
#   # Some patterns for the metrics to minimize
# minimize_pattern <- "([Ee]rror)|(AEPE)|(MPJPE)"
#   # The rest of the minimize metrics not picked up by the patterns
# minimize_metrics <-
#   c(
#     "MAE",
#     "MSE",
#     "MAE @ 12 step",
#     "NME",
#     "RMSE",
#     "RMSE@80%Train",
#     "RMS",
#     "Viewpoint I AEPE",
#     "rect mask l2 err",
#     "mse (10^-3)",
#     "ERR@20",
#     "free-form mask l1 err	1",
#     "free-form mask l2 err",
#     "free-form mask l1 err",
#     "Search Time (GPU days)",
#     "Cumulative regret",
#     "Number of params",
#     "Params",
#     "PARAMS",
#     "FID",
#     "MR",
#     "NLL",
#     "Log Loss"
#   )
#===============================================================================

dest <- fs::path(dir_data, "evaluation_tables.json")
download.file(url_data, destfile = dest)

original_json <-
  dest %>%
  jsonlite::read_json()

minimize_metrics <-
  yaml::read_yaml(file_minimize_metrics)$minimize_metrics

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
    #multiplier == "%"               ~ as.double(metric) / 100,
    TRUE                            ~ as.double(metric)
  )
}

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
    across(where(is.character), ~ na_if(., "")),
    minimize =
      metric_name %in% minimize_metrics |
      str_detect(metric_name, minimize_pattern)
  ) %>%
  unite(col = "group", task, dataset, metric_name, remove = FALSE)

sota_all %>%
  count(group, sort = TRUE) %>%
  write_rds(file_group_counts)

v <-
  sota_all %>%
  group_by(group) %>%
  arrange(paper_date) %>% # sometimes, papers have multiple models. We only want the best one
  filter(
    if_else(
      minimize,
      metric_result == cummin(metric_result),
      metric_result == cummax(metric_result)
    )
  ) %>%
  group_by(group, paper_date) %>% # Only include the minimum/maximum value from a paper
  filter(
    if_else(
      minimize,
      metric_result == min(metric_result),
      metric_result  == max(metric_result)
    )
  ) %>%
  group_by(group, metric_result) %>%
  slice_min(order_by = paper_date, with_ties = FALSE) %>% # sometimes there are papers with identical metrics
  ungroup() %>%
  select(-datasets, -sota, -rows, -multiplier, -metric_result_original) %>%
  arrange(task, dataset, paper_date) %>%
  rowwise() %>%
  mutate(
    result_id =
      digest::digest(
        str_glue("{group}{paper_title}{paper_date}{model_name}"),
        algo = "md5"
      ),
    .before = group
  ) %>%
  ungroup()

assertthat::assert_that(
  nrow(v) == n_distinct(v$result_id),
  msg = "Error: Result IDs are not unique."
)

v %>%
  write_rds(file_out)




