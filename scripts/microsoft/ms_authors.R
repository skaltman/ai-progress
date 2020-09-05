# Microsoft authors data

# Author: Sara Altman
# Version: 2020-04-04

# Libraries
library(tidyverse)

# Parameters
file_ms <- here::here("data/microsoft/ms_papers.rds")
file_arxiv <- here::here("data/arxiv/arxiv_papers.rds")
file_authors <-  here::here("data/microsoft/ms_authors.rds")
file_authors_subfields <-
  here::here("data/microsoft/ms_authors_subfields.rds")
file_authors_citations <-
  here::here("data/microsoft/ms_authors_citations.rds")
  # Citation thresholds
thresholds <- c(1, 5, 10, 100, 1000)
#===============================================================================

entry_dates <- function(data, ...) {
  data %>%
    drop_na(author_name, author_id) %>% # 1% of the data is missing from Microsoft
    group_by(author_id, ...) %>%
    slice_max(order_by = date, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    count(date, ..., name = "new_authors") %>%
    arrange(..., date) %>%
    group_by(...) %>%
    mutate(total_authors = cumsum(new_authors)) %>%
    ungroup()
}

entry_dates_threshold <- function(threshold) {
  authors %>%
    group_by(author_id) %>%
    filter(any(citations >= threshold)) %>%
    ungroup() %>%
    entry_dates()
}


papers_arxiv <-
  file_arxiv %>%
  read_rds()

papers_ms <-
  file_ms %>%
  read_rds()

authors <-
  papers_ms %>%
  left_join(
    papers_arxiv %>% select(id, query_id),
    by = c("id_arxiv" = "id")
  ) %>%
  select(id_ms, authors, date, citations, subfield = query_id) %>%
  unnest(col = authors, keep_empty = TRUE) %>%
  select(-authors) %>%
  rename(
    author_name = AuN,
    author_id = AuId
  )

new_authors <-
  authors %>%
  entry_dates() %>%
  write_rds(file_authors)

zero <-
  authors %>%
  group_by(author_id) %>%
  filter(all(citations == 0)) %>%
  ungroup() %>%
  entry_dates()

thresholds %>%
  set_names(
    ~ if_else(
      . == 1,
      "At least 1 citation",
      str_glue("At least {.} citations") %>% as.character()
    )
  ) %>%
  map_dfr(entry_dates_threshold, .id = "citation_group") %>%
  bind_rows(zero %>% mutate(citation_group = "No citations")) %>%
  relocate(citation_group, .after = everything()) %>%
  write_rds(file_authors_citations)

# y <-
# bind_rows(
#   "No citations" = zero,
#   "At least 1 citation" = one,
#   "At least 5 citations" = five,
#   "At least 10 citations" = ten,
#   .id = "citation_group"
# ) %>%
#   relocate(citation_group, .after = everything()) %>%
#   write_rds(file_authors_citations)

authors %>%
  entry_dates(subfield) %>%
  write_rds(file_authors_subfields)

