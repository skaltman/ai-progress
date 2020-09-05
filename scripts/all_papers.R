# Read in all Microsoft data

# Author: Sara Altman
# Version: 2020-07-28

# Libraries
library(tidyverse)
library(microdemic)
library(lubridate)
library(aRxiv)

# Parameters
file_papers_ms <- here::here("data/microsoft/ms_papers.rds")
START_YEAR_ARXIV <- 1991
file_out <- here::here("data/all/papers.rds")
#===============================================================================

ai_papers <-
  file_papers_ms %>%
  read_rds() %>%
  drop_na(date) %>%
  count(year = year(date))

start_year <- min(ai_papers$year, na.rm = TRUE)

all_arxiv <-
  str_glue("submittedDate:[{dates_arxiv} TO {dates_arxiv + 1}]") %>%
  set_names(dates_arxiv) %>%
  map_dfr(~ tibble(arxiv = arxiv_count(.) %>% as.integer()), .id = "year")

dates_ms <- min(year(papers_ms$date), na.rm = TRUE):year(today())

all_ms <-
  str_glue("Y={dates_ms}") %>%
  set_names(dates_ms) %>%
  map_dfr(ma_calchist, atts = "Id", .id = "year") %>%
  select(year, ms = num_entities)

v <-
  ai_papers %>%
  rename(ai = n) %>%
  left_join(all_arxiv %>% mutate(year = as.double(year)), by = "year") %>%
  left_join(all_ms %>% mutate(year = as.double(year)), by = "year") %>%
  write_rds(file_out)

