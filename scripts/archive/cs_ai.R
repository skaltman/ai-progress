# Just cs.AI

# Author: Sara Altman
# Version: 2020-02-08

# Libraries
library(tidyverse)
library(arxivapi)

# Parameters
file_subfield_counts <- here::here("data/subfield_counts.rds")
subfield_code <- "cs.AI"
file_out <- here::here("data/cs_ai.rds")
#===============================================================================

limit <-
  read_rds(file_subfield_counts) %>%
  filter(code == subfield_code) %>%
  pull(count)

result <-
  arxiv_request(
    query = "cat:cs.AI",
    start = 0,
    limit = limit,
    batch_size = 1000,
    sleep = 3
  )

write_rds(result, file_out)
