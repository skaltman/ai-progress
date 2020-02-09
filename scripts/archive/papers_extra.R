# Find the AI related papers not categorized in the AI subfields

# Author: Sara Altman
# Version: 2020-01-31

# Libraries
library(tidyverse)
library(aRxiv)
library(fs)

# Parameters
file_subfields <- here::here("data/subfields.rds")
file_papers_extra <- here::here("data/papers_extra.rds")
keywords <- "artificial intelligence"
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

subfields <- read_rds(file_subfields)

query_exclude_subfields <-
  subfields %>%
  pull(code) %>%
  str_c(collapse = " ANDNOT ")

query <- str_glue('abstract="{keywords}" ANDNOT {query_exclude_subfields}')

# There are 17,336 papers whose abstracts contain "AI", but who are not classified
# under one of the subcategories
limit <- arxiv_count(query)

start <- 0

if (file_exists(file_papers_extra)) {
  start <- nrow(read_rds(file_papers_extra))
}

stopifnot(start < limit)

papers <-
  arxiv_search(
    query,
    start = start,
    limit = limit - start,
    batchsize = 2000,
    force = TRUE
  ) %>%
  as_tibble() %>%
  select(variables) %>%
  mutate_at(
    vars(authors, categories),
    str_replace_all,
    pattern = "\\|",
    replacement = ", "
  ) %>%
  mutate_at(vars(contains("date")), lubridate::as_date)

if (file_exists(file_papers_extra)) {
  papers <-
    bind_rows(read_rds(file_papers_extra), papers)
}

papers %>%
  write_rds(file_papers_extra, compress = "gz")

