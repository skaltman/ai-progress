# Crossref data

# Author: Sara Altman
# Version: 2020-02-24

# Libraries
library(tidyverse)
library(rcrossref)
library(assertthat)

# Parameters
file_papers <- here::here("data/papers.rds")

#===============================================================================

titles <-
  file_papers %>%
  read_rds() %>%
  select(id, title)

get_doi <- function(paper_title, n = 3) {
  paper_title <- str_to_lower(paper_title)

  response <-
    cr_works(query = paper_title, limit = n)$data %>%
    filter(str_to_lower(title) == paper_title) %>%
    distinct(doi)

  assert_that(nrow(response) > 0, msg = "No papers found.")

  assert_that(nrow(response) == 1, msg = "Multiple papers found.")

  response$doi
}

safely_get_doi <- safely(get_doi, otherwise = NA_character_)

tictoc::tic()
x <-
  titles %>%
  slice(1) %>%
  mutate(
    result = map(title, safely_get_doi),
    doi = map_chr(result, "result")
  )
tictoc::toc()

# will take 53 hours as is
