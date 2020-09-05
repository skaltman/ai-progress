# Microsoft tables

# Author: Sara Altman
# Version: 2020-04-08

# Libraries
library(tidyverse)
library(googlesheets4)
library(lubridate)

# Parameters
file_authors <- here::here("data/microsoft/ms_authors_new.rds")
file_authors_subfields <-
  here::here("data/microsoft/ms_authors_new_subfields.rds")
file_subfields <- here::here("data/arxiv/subfields.rds")

sheet_key <- "1NB22PAhoFVAYxzNEROrBchbtmDm15ZG6jLeayb-gsyE"
ws_year <- "New researchers per year"
ws_subfields <- "New researchers per year per subfield"
#===============================================================================

new_authors <-
  file_authors %>%
  read_rds()

new_authors %>%
  group_by(year = year(date)) %>%
  summarize(new_authors = sum(new_authors)) %>%
  mutate(
    total_authors = cumsum(new_authors),
    percent_new = new_authors / total_authors * 100,
    percent_growth =
      ((total_authors - lag(total_authors)) / lag(total_authors)) * 100
  ) %>%
  rename(
    "Year" = year,
    "Total new researchers publishing on arXiv" = new_authors,
    "Total researchers who have published on arXiv" = total_authors,
    "Percent new researchers" = percent_new,
    "Percent growth of total researchers" = percent_growth
  ) %>%
  sheets_write(sheet_key, ws_year)

subfield_growth <-
  file_authors_subfields %>%
  read_rds() %>%
  left_join(
    read_rds(file_subfields) %>% select(subfield_name = subfield, code),
    by = c("subfield" = "code")
  ) %>%
  mutate(
    subfield =
      str_glue("{subfield_name} ({subfield})") %>% as.character()
  ) %>%
  group_by(year = year(date), subfield) %>%
  summarize(new_authors = sum(new_authors)) %>%
  ungroup() %>%
  mutate(total_authors = cumsum(new_authors)) %>%
  select(-new_authors) %>%
  pivot_wider(
    names_from = subfield,
    values_from = total_authors,
    values_fill = list(total_authors = 0)
  )

subfield_growth %>%
  sheets_write(sheet_key, ws_subfields)

subfield_growth %>%
  filter(year >= 1999) %>%
  summarize_at(
    vars(-year),
    list(
      `1999-2019` = ~ .[year == 2019] / .[year == 1999],
      `2009-2019` = ~ .[year == 2019] / .[year == 2009]
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = c("field", "years"),
    names_sep = "_",
    values_to = "factor_increase"
  ) %>%
  pivot_wider(names_from = field, values_from = factor_increase) %>%
  sheets_edit(
    ss = sheet_key,
    data = .,
    sheet = ws_year,
    range = cell_rows(43:45)
  )


