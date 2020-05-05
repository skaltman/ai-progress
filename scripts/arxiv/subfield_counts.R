# Counts of number of papers published in each subfield

# Author: Sara Altman
# Version: 2020-01-31

# Libraries
library(tidyverse)
library(aRxiv)

# Parameters
file_subfields <- here::here("data/arxiv/subfields.yml")
file_out <- here::here("data/arxiv/subfield_counts.rds")
#===============================================================================

subfield_counts <-
  yaml::read_yaml(file_subfields) %>%
  map_dfr(
    ~ tibble(
      field = .$field,
      code = .$code,
      count = arxiv_count(str_glue("cat:{.$code}")) %>% as.integer()
    ),
    .id = "subfield"
  ) %>%
  write_rds(file_out)
