# Download papers data from arxiv API

# Reads in existing papers.rds (if it exists), and then uses the number of papers
# in papers.rds to determine which new papers to ask the API for

# Author: Sara Altman
# Version: 2020-01-30

# Libraries
library(tidyverse)
library(arxivapi)

# Parameters
  # Total number of papers by subfield
script_subfield_counts <- here::here("scripts/arxiv/subfield_counts.R")
file_subfield_counts <- here::here("data/arxiv/subfield_counts.rds")
  # Output file
file_out <- here::here("data/arxiv/papers.rds")
  # Directory to put data
dir_data <- here::here("data/arxiv/")
  # Batch size (for querying arxiv API)
BATCH_SIZE <- 1000
  # Seconds to slip between queries
SLEEP <- 3
  # Column order for final, cleaned, unique data
col_order <-
  c(
    "id",
    "title",
    "authors",
    "date_submitted" = "submitted",
    "date_updated" = "updated",
    "primary_category",
    "categories",
    "reference" = "journal_ref",
    "doi",
    "query_id"
  )
#===============================================================================

source(script_subfield_counts)

get_subfield_papers <- function(code, limit) {
  query <- str_glue("cat:{code}")

  message("Retrieving papers for ", code)

  papers_subfield <-
    arxiv_request(
      query = query,
      start = 0,
      limit = limit,
      batch_size = BATCH_SIZE,
      sleep = SLEEP
    ) %>%
    mutate(query_id = code) %>%
    write_rds(path_subfield_data(code)) # write out data for one subfield to retain progress

  papers_subfield
}

path_subfield_data <- function(code) {
  fs::path(
    dir_data,
    str_replace(code, "\\.", "_"),
    ext = "rds"
  )
}

papers <-
  read_rds(file_subfield_counts) %>%
  select(code, limit = count) %>%
  pmap_dfr(., get_subfield_papers) %>%
  mutate_at(
    vars(authors, categories),
    str_replace_all,
    pattern = "\\|",
    replacement = ", "
  ) %>%
  mutate_at(vars(submitted, updated), lubridate::as_date) %>%
  mutate_if(is.character, na_if, "")

# Find the distinct papers and write out
papers %>%
  distinct(id, .keep_all = TRUE) %>%
  distinct(title, .keep_all = TRUE) %>%
  select(col_order) %>% # There are 123 duplicate titles. Most of these appear to be the same paper, listed multiple times
  write_rds(file_out, compress = "gz")
