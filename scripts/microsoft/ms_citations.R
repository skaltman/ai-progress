# Microsoft Academic Knowledge API

# Author: Sara Altman
# Version: 2020-03-22

# Libraries
library(tidyverse)
library(microdemic)
library(googlesheets4)

# Parameters
# MIN <- 90001
# MAX <- 106091
file_papers <- here::here("data/arxiv/papers.rds")
# file_out <- here::here(str_glue("data/microsoft/ms_citations_{MAX}.rds"))
file_out <- here::here("data/microsoft/ms_citations.rds")
response_vars <-
  c(
    paper_id = "Id",
    paper_title = "DN",
    doi = "DOI",
    date_published = "D",
    author_name = "AA.AuN",
    author_id = "AA.AuId",
    citation_count = "CC"
  )
query <- "Ti=='{title_query}'"
sheet_key <- "1NB22PAhoFVAYxzNEROrBchbtmDm15ZG6jLeayb-gsyE"
ws <- "Citations"

# col_order <-
#   c(
#     "id",
#     "title",
#     "authors",
#     "date_submitted" = "submitted",
#     "date_updated" = "updated",
#     "primary_category",
#     "categories",
#     "reference" = "journal_ref",
#     "doi",
#     "query_id",
#     "citations"
#   )
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
    id_ms = NA_character_,
    title_arxiv = title,
    title_ms = NA_character_,
    citations = NA_integer_,
    authors = NA_character_,
    date = NA_character_,
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

    result <-
      result %>%
      transmute(
        id_arxiv = id,
        id_ms = Id,
        title_arxiv = title,
        title_ms = DN,
        citations = CC,
        authors = AA,
        date = D,
        doi = DOI,
        log_prob = logprob
      ) %>%
      mutate_at(vars(id_ms, id_arxiv, doi), as.character)

    result
  }
}

possibly_get_microsoft <- possibly(get_microsoft, otherwise = tibble())

papers <-
  read_rds(file_papers)

ms_citations <-
  papers %>%
  mutate(n = row_number()) %>%
  select(id, title, n) %>%
  slice(MIN:MAX) %>%
  pmap_dfr(possibly_get_microsoft)

ms_citations %>%
  mutate(date = lubridate::ymd(date)) %>%
  write_rds(file_out, compress = "gz")

ms_citations %>%
  select(-authors) %>%
  googlesheets4::sheets_append(ss = sheet_key, sheet = ws)


