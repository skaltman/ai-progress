# Download papers data from arxiv API

# Reads in existing papers.rds (if it exists), and then uses the number of papers
# in papers.rds to determine which new papers to as the API for

# Author: Sara Altman
# Version: 2020-01-30

# Libraries
library(tidyverse)
library(aRxiv)

# Parameters
file_subfield_counts <- here::here("data/subfield_counts.rds")
file_papers <- here::here("data/papers_incremental.rds")
file_backup <- here::here("data/backup.rds")
variables <-
  c(
    "id",
    "title",
    "authors",
    date_submitted = "submitted",
    date_updated = "updated",
    "primary_category",
    "categories",
    reference = "journal_ref",
    "doi"
  )
STEP <- 2000
#===============================================================================

tidy_arxiv <- function(code, start = 0, limit, batchsize = 1000) {
  query <- str_glue("cat:{code}")
  batch <-
    arxiv_search(
      query = query,
      start = start,
      limit = limit - start,
      batchsize = batchsize,
      force = TRUE
    ) %>%
    as_tibble() %>%
    select(variables) %>%
    mutate(query_id = code)

  batch
}

possibly_tidy_arxiv <- possibly(tidy_arxiv, otherwise = NA)

papers <-
  read_rds(file_subfield_counts) %>%
  rename(limit = count) %>%
  mutate(limit = map2(STEP, limit, seq, by = STEP)) %>%
  unnest(limit) %>%
  group_by(code) %>%
  mutate(start = lag(limit, default = 0)) %>%
  ungroup() %>%
  select(code, start, limit) %>%
  mutate(data = pmap(., possibly_tidy_arxiv))

papers %>%
  write_rds(file_backup, compress = "gz")

papers %>%
  select(data) %>%
  unnest(data) %>%
  mutate_at(
      vars(authors, categories),
      str_replace_all,
      pattern = "\\|",
      replacement = ", "
  ) %>%
  mutate_at(vars(contains("date")), lubridate::as_date) %>%
  write_rds(file_papers, compress = "gz")


