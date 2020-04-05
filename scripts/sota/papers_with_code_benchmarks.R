# Papers with code

# Author: Name
# Version: 2020-02-18

# Libraries
library(tidyverse)

# Parameters
file_benchmarks <- here::here("data-raw/evaluation_tables.json")
file_papers <- here::here("data-raw/papers_with_abstracts.json")

#===============================================================================

get_names <- function(data) {
  data %>%
    map(names) %>%
    unlist() %>%
    unique()
}

get_variable <- function(element, variable) {
  x <- element[[variable]] %||% NA_character_
  if (is_empty(x)) {
    return(NA_character_)
  } else {
    return(x)
  }
}

map_variable <- function(data, variable) {
  tryCatch(
    map_chr(data, get_variable, variable),
    error = function(c) map(data, get_variable, variable)
  )
}


benchmarks <-
  jsonlite::read_json(file_benchmarks)

v <-
  benchmarks %>%
  get_names() %>%
  set_names() %>%
  map_dfc(map_variable, data = benchmarks) %>%
  select(
    task,
    categories,
    datasets,
    subtasks,
    description,
    source_link,
    synonyms
  )

get_names(v[["datasets"]])




