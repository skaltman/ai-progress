# Download data from arxiv API, write to Google Sheets

# Author: Sara Altman
# Version: 2020-01-30

# Libraries
library(tidyverse)
library(aRxiv)
library(googlesheets4)

# Parameters
file_subfield_counts <- "data/subfield_counts.rds"
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
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws <- "Papers"
file_out <- "papers.rds"
#===============================================================================

tidy_arxiv <- function(code, start = 0, limit, batchsize = 1000) {
  query <- str_glue("cat:{code}")
  batch <-
    arxiv_search(
      query = query,
      start = start,
      limit = limit,
      batchsize = batchsize,
      force = TRUE
    ) %>%
    as_tibble() %>%
    select(variables) %>%
    mutate(query_id = code)

  batch
}

subfield_counts <- read_rds(file_subfield_counts)

papers <-
  subfield_counts %>%
  select(code, limit = count) %>%
  mutate(limit = 2) %>%
  pmap_dfr(tidy_arxiv) %>%
  mutate_at(
    vars(authors, categories),
    str_replace_all,
    pattern = "\\|",
    replacement = ", "
  ) %>%
  mutate_at(vars(contains("date")), lubridate::as_date)

# Check that ID uniquely identifies papers
v <-
  papers %>%
  select(-query_id) %>%
  count(!!!., sort = TRUE)

stopifnot(n_distinct(v$id) == nrow(v))

# If ID uniquely identifies papers, throw out duplicates
papers %>%
  distinct(id, .keep_all = TRUE) %>%
  write_rds(file_out, compress = "gz")

papers %>%
  sheets_write(ss = sheet_key, sheet = ws)

