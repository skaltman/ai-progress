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
file_papers <- here::here("data/papers.rds")
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

limits <-
  read_rds(file_subfield_counts) %>%
  select(code, limit = count)

if (fs::file_exists(file_papers)) {
  limits <-
    read_rds(file_papers) %>%
    count(code = query_id, name = "start") %>%
    left_join(limits, by = c("code"))
} else {
  limits <-
    limits %>%
    mutate(start = 0) %>%
    select(code, start, limit)
}

papers <-
  limits %>%
  filter(start != limit) %>%
  pmap_dfr(tidy_arxiv) %>%
  mutate_at(
    vars(authors, categories),
    str_replace_all,
    pattern = "\\|",
    replacement = ", "
  ) %>%
  mutate_at(vars(contains("date")), lubridate::as_date)


read_rds(file_papers) %>%
  bind_rows(papers) %>%
  write_rds(file_papers, compress = "gz")


