# Authors

# Author: Sara Altman
# Version: 2020-02-09

# Libraries
library(tidyverse)
library(googlesheets4)

# Parameters
file_papers <- here::here("data/arxiv/papers.rds")
file_authors <- here::here("data/arxiv/arxiv_authors.rds")
file_authors_new <- here::here("data/arxiv/arxiv_authors_new.rds")
file_authors_subfields <- here::here("data/arxiv/arxiv_authors_subfields.rds")

sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws_authors_new <- "Researchers"
ws_authors_subfields <- "Researchers by subfield"
ws_authors_summary <- "Researcher totals"

#===============================================================================

clean_authors <- function(authors) {
  authors_clean <-
    authors %>%
    str_remove_all("[;\\.']*(\\\\and)*") %>%
    str_replace_all(pattern = "~", replacement = " ") %>%
    str_replace_all("  ", " ") %>%
    str_trim(side = "both")
}

papers <-
  file_papers %>%
  read_rds()

authors <-
  papers %>%
  select(id, submitted, authors, query_id) %>%
  separate_rows(authors, sep = ", ") %>%
  rename(author = authors) %>%
  mutate(
    author =
      str_remove_all(author, "[;\\.']*(\\\\and)*") %>%
      str_replace_all(pattern = "~", replacement = " ") %>%
      str_replace_all("  ", " ") %>%
      str_trim(side = "both")
  ) %>%
  filter(str_detect(author, " ")) %>% # currently removes 239 rows. Need to figure out how to deal with the firstLast type
  write_rds(file_authors, compress = "gz")

authors %>%
  group_by(author) %>%
  top_n(n = -1, wt = submitted) %>%
  ungroup() %>%
  distinct(author, submitted) %>%
  count(submitted, name = "new_authors") %>%
  arrange(submitted) %>%
  mutate(total_authors = cumsum(new_authors)) %>%
  write_rds(file_authors_new) %>%
  sheets_write(sheet_key, ws_authors_new)

authors %>%
  group_by(author, subfield = query_id) %>%
  top_n(n = -1, wt = submitted) %>%
  ungroup() %>%
  distinct(author, submitted, subfield) %>%
  count(submitted, subfield, name = "new_authors") %>%
  arrange(subfield, submitted) %>%
  group_by(subfield) %>%
  mutate(total_authors = cumsum(new_authors)) %>%
  write_rds(file_authors_subfields) %>%
  sheets_write(sheet_key, ws_authors_subfields)

authors %>%
  group_by(query_id) %>%
  summarize(num_researchers = n_distinct(author, na.rm = TRUE)) %>%
  add_row(
    query_id = "total",
    num_researchers = n_distinct(authors$author, na.rm = TRUE)
  ) %>%
  arrange(desc(num_researchers)) %>%
  sheets_write(sheet_key, ws_authors_summary)


