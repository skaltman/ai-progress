# Description

# Author: Sara Altman
# Version: 2020-01-30

# Libraries
library(tidyverse)
library(aRxiv)
library(googlesheets)

# Parameters
subfields <-
  tribble(
    ~field,             ~subfield,                                ~code,
    "Statistics",       "Machine Learning",                        "stat.ML",
    "Computer Science", "Artificial Intelligence",                 "cs.AI",
    "Computer Science", "Computation and Language",                "cs.CL",
    "Computer Science", "Computer Vision and Pattern Recognition", "cs.CV",
    "Computer Science", "Learning",                                "cs.LG",
    "Computer Science", "Neural and Evolutionary Computing",       "cs.NE",
    "Computer Science", "Robotics",                                "cs.RO"
  )
variables <-
  c(
    "id",
    "title",
    "authors",
    date_submitted = "submitted",
    date_updated = "updated",
    "primary_category",
    "categories"
  )
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws_subfields <- "Subfield counts"
#===============================================================================

tidy_arxiv <- function(code, start = 0, limit, batchsize = 1000) {
  query <- str_glue("cat:{code}")
  batch <-
    arxiv_search(
      query = query,
      start = start,
      limit = limit,
      batchsize = batchsize,
      force = TRUE
    ) %>%
    as_tibble() %>%
    select(variables)

  batch
  # nrow_batch <- nrow(batch)
  #
  # if (nrow_batch == limit - start) {
  #   return(batch)
  # } else {
  #   bind_rows(
  #     batch,
  #     tidy_arxiv(
  #       code,
  #       start = nrow_batch,
  #       limit = (limit - nrow_batch + 1),
  #       batchsize = batchsize
  #     )
  #   )
  # }

  # # If arxiv_search() was not able to get all papers in one go
  # if (nrow_batch < (limit - start)) {
  #   batch_2 <-
  #     arxiv_search(
  #       query = query,
  #       start = nrow_batch,
  #       limit = (limit - nrow_batch + 1),
  #       batchsize = batchsize,
  #       force = TRUE
  #     ) %>%
  #     as_tibble()
  #
  #   batch <-
  #     bind_rows(batch, batch_2) %>%
  #     select(variables)
  # }

  #stopifnot(nrow(batch) == (limit - start))

  # batch
}

all <-
  subfield_counts %>%
  select(code, limit = count) %>%
  # mutate(limit = 1000) %>%
  pmap_dfr(tidy_arxiv) %>%
  mutate_at(vars(authors, categories), str_split, pattern = "\\|") %>%
  mutate_at(vars(contains("date")), lubridate::as_date)



subfield_counts %>%
  sheets_write(ss = sheet_key, sheet = ws_subfields)

stat_ml_ <- tidy_arxiv(code = "stat.ML", limit = 35113)
