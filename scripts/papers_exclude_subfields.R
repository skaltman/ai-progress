# Find the AI related papers not categorized in the AI subfields

# Author: Sara Altman
# Version: 2020-01-31

# Libraries
library(tidyverse)

# Parameters
file_subfields <- here::here("data/subfields.rds")
keywords <- "AI"
#===============================================================================

subfields <- read_rds(file_subfields)

query_exclude_subfields <-
  subfields %>%
  pull(code) %>%
  str_c(collapse = " ANDNOT ")

query <- str_glue('abstract="{keywords}" ANDNOT {query_exclude_subfields}')

# There are 17,336 papers whose abstracts contain "AI", but who are not classified
# under one of the subcategories
num_papers <- arxiv_count(query)

# papers <-
#   arxiv_search(query, limit = num_papers, batchsize = 1000, force = TRUE)
