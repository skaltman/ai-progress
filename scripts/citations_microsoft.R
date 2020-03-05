# Microsoft Academic Knowledge API

# Author: Sara Altman
# Version: 2020-02-29

# Libraries
library(tidyverse)
library(microdemic)
library(googlesheets4)

# Parameters
file_papers <- here::here("data/papers.rds")
file_out <- here::here("data/citations_100000.rds")
response_vars <- c('Id', 'AA.AuN', 'DN', 'CC', 'DOI')
query <- "Ti=='{title_query}'"
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
sheet_ws <- "papers_citations"
#===============================================================================

clean_title <- function(title) {
  title %>%
    str_to_lower() %>%
    str_remove_all("'") %>%
    str_remove_all("\n") %>%
    str_replace_all("[,?()\\+\"!]", "") %>%
    str_replace_all("[-:/]", " ") %>%
    str_replace_all("\\s{2,}", " ")
}

empty_response <- function(id, title) {
  tibble(
    id_arxiv = id,
    id_mc = NA_character_,
    title_arxiv = title,
    title_mc = NA_character_,
    citations = NA_integer_,
    authors = NA_character_,
    doi = NA_character_,
    log_prob = NA_real_,
  ) %>%
    mutate(authors = list(authors))
}

get_microsoft <- function(id, title, n) {

  title_query <- clean_title(title)

  result <-
    ma_evaluate(
      query = str_glue(query),
      count = 1,
      atts = response_vars
    )

  if (n %% 100 == 0) print(str_glue("{n} papers found."))

  if (nrow(result) == 0) {
    empty_response(id, title)
  } else {

    if (!"DOI" %in% names(result)) {
      result <-
        result %>%
        mutate(DOI = NA_character_)
    }

    result %>%
      transmute(
        id_arxiv = id,
        id_mc = Id,
        title_arxiv = title,
        title_mc = DN,
        citations = CC,
        authors = AA,
        doi = DOI,
        log_prob = logprob
      ) %>%
      mutate_at(vars(id_mc, id_arxiv, doi), as.character)
  }
}

possibly_get_microsoft <- possibly(get_microsoft, otherwise = tibble())

citations <-
  read_rds(file_papers) %>%
  mutate(n = row_number()) %>%
  select(id, title, n) %>%
  pmap_dfr(possibly_get_microsoft) %>%
  write_rds(file_out, compress = "gz")


# Join with papers data and write to Google Sheets


