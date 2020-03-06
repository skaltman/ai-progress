# Download papers data from arxiv API

# Reads in existing papers.rds (if it exists), and then uses the number of papers
# in papers.rds to determine which new papers to as the API for

# Author: Sara Altman
# Version: 2020-01-30

# Libraries
library(tidyverse)
library(arxivapi)
library(arrow)

# Parameters
file_subfield_counts <- here::here("data/subfield_counts.rds")
file_all <- here::here("data/papers_all.rds")
file_distinct <- here::here("data/papers.rds")
file_distinct_parquet <- here::here("data/papers.parquet")
dir_data <- here::here("data")
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws <- "Papers"
BATCH_SIZE <- 1000
SLEEP <- 3

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

get_subfield_papers <- function(code, start = 0, limit) {
  query <- str_glue("cat:{code}")

  message("Retrieving papers for ", code)

  papers_subfield <-
    arxiv_request(
      query = query,
      start = start,
      limit = limit,
      batch_size = BATCH_SIZE,
      sleep = SLEEP
    ) %>%
    mutate(query_id = code) %>%
    write_rds(path_subfield_data(code))

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
  mutate(start = 0) %>%
  select(code, start, limit = count) %>%
  pmap_dfr(., get_subfield_papers) %>%
  mutate_at(
    vars(authors, categories),
    str_replace_all,
    pattern = "\\|",
    replacement = ", "
  ) %>%
  mutate_at(vars(submitted, updated), lubridate::as_date) %>%
  mutate_if(is.character, na_if, "")

papers %>%
  write_rds(file_all, compress = "gz")

papers %>%
  distinct(id, .keep_all = TRUE) %>%
  distinct(title, .keep_all = TRUE) %>%
  select(col_order) %>% # There are 123 duplicate titles. Most of these appear to be the same paper, listed multiple times (see papers.Rmd)
  write_rds(file_distinct, compress = "gz") %>%
  write_parquet(file_distinct_parquet) %>%
  write_sheet(ss = sheet_key, sheet = ws)

sheet_key <- "1wmfRjPW8yY-zGrrFFiWtNaKpWvKItrKLHmxEBTzkxyk"
