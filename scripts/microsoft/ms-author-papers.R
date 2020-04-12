# Get all papers for all authors in our data

# Author: Sara Altman
# Version: 2020-04-05

# Libraries
library(tidyverse)
library(microdemic)

# Parameters
MIN <- 90001
# MAX <- 90000
file_authors <- here::here("data/microsoft/ms_authors.rds")
file_out <- here::here("data/microsoft/ms_author_data_max.rds")
author_query <- "And(Ty='1',Id={author_id})"
response_vars <-
  c(
    author_id = "Id",
    author_name = "AuN",
    n_citations = "CC",
    n_papers = "PC"
  )
#===============================================================================

authors <-
  file_authors %>%
  read_rds() %>%
  distinct(author_name, author_id)

get_papers <- function(author_id, n) {
  if (n %% 1000 == 0) {
    print(str_glue("Found {n} authors."))
  }

  ma_evaluate(
    query = str_glue(author_query),
    atts = unlist(response_vars)
  ) %>%
    select(response_vars)
}

v <-
  authors %>%
  slice(MIN:nrow(.)) %>%
  drop_na(author_id) %>%
  transmute(author_id, n = row_number()) %>%
  pmap_dfr(get_papers)

v %>%
  write_rds(file_out)
