# Microsoft authors data

# Author: Sara Altman
# Version: 2020-04-04

# Libraries
library(tidyverse)
library(googlesheets4)

# Parameters
file_ms <- here::here("data/microsoft/ms_citations.rds")
file_arxiv <- here::here("data/arxiv/papers.rds")

file_authors <-  here::here("data/microsoft/ms_authors.rds")
file_authors_new <- here::here("data/microsoft/ms_authors_new.rds")
file_authors_new_10 <- here::here("data/microsoft/ms_authors_new_10.rds")
file_authors_new_subfields <-
  here::here("data/microsoft/ms_authors_new_subfields.rds")
file_authors_new_subfields_10 <-
  here::here("data/microsoft/ms_authors_new_subfields_10.rds")

sheet_key <- "1NB22PAhoFVAYxzNEROrBchbtmDm15ZG6jLeayb-gsyE"
ws_all <- "Researchers"
ws_10 <- "Researchers with 10+ citations"
ws_1 <- "Researchers with 1+ citations"
ws_subfields <- "Researchers - Subfields"
ws_subfields_10 <- "Researchers with 10+ citations - Subfields"
ws_subfields_1 <- "Researchers with 1+ citations - Subfields"
#===============================================================================

author_entry_dates <- function(data, ...) {
  data %>%
    drop_na(author_name, author_id) %>% # will need to get some author data from arxiv
    group_by(author_id, ...) %>%
    top_n(n = -1, wt = date) %>%
    ungroup() %>%
    distinct(author_id, date, ...) %>%
    count(date, ..., name = "new_authors") %>%
    arrange(..., date) %>%
    group_by(...) %>%
    mutate(total_authors = cumsum(new_authors)) %>%
    ungroup()
}

arxiv <-
  file_arxiv %>%
  read_rds()

ms <-
  file_ms %>%
  read_rds()

authors <-
  ms %>%
  left_join(
    arxiv %>% select(id, query_id),
    by = c("id_arxiv" = "id")
  ) %>%
  select(id_ms, authors, date, citations, subfield = query_id) %>%
  unnest(col = authors, keep_empty = TRUE) %>%
  select(-authors) %>%
  rename(
    author_name = AuN,
    author_id = AuId
  )

authors %>%
  select(-citations) %>%
  write_rds(file_authors)

new_authors_all <-
  authors %>%
  author_entry_dates() %>%
  write_rds(file_authors_new) %>%
  sheets_write(sheet_key, sheet = ws_all)

new_authors_10 <-
  authors %>%
  group_by(author_id) %>%
  filter(any(citations >= 10)) %>%
  ungroup() %>%
  author_entry_dates() %>%
  write_rds(file_authors_new_10) %>%
  sheets_write(sheet_key, sheet = ws_10)

authors %>%
  group_by(author_id) %>%
  filter(any(citations >= 1)) %>%
  ungroup() %>%
  author_entry_dates() %>%
  sheets_write(sheet_key, sheet = ws_1)

authors_by_subfield <-
  authors %>%
  author_entry_dates(subfield) %>%
  write_rds(file_authors_new_subfields) %>%
  sheets_write(sheet_key, ws_subfields)

authors_by_subfield_10 <-
  authors %>%
  group_by(author_id) %>%
  filter(any(citations >= 10)) %>%
  ungroup() %>%
  author_entry_dates(subfield) %>%
  write_rds(file_authors_new_subfields_10) %>%
  sheets_write(sheet_key, sheet = ws_subfields_10)

authors %>%
  group_by(author_id) %>%
  filter(any(citations >= 1)) %>%
  ungroup() %>%
  author_entry_dates(subfield) %>%
  sheets_write(sheet_key, sheet = ws_subfields_1)
