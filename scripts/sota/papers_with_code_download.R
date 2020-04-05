# Download Papers with Code data

# Author: Sara Altman
# Version: 2020-02-18

# Libraries
library(tidyverse)
library(fs)

# Parameters
urls <-
  c(
    papers_with_abstracts =
      "https://paperswithcode.com/media/about/papers-with-abstracts.json.gz",
    links_between_papers_code =
      "https://paperswithcode.com/media/about/links-between-papers-and-code.json.gz",
    evaluation_tables =
      "https://paperswithcode.com/media/about/evaluation-tables.json.gz"
  )
file_dest <- here::here("data-raw/")

#===============================================================================

if (!dir_exists(file_dest)) {
  dir_create(file_dest)
}

download_unzip <- function(url, dest) {
  file <- path(file_dest, dest, ext = "json.gz")
  download.file(url, destfile = file)
  R.utils::gunzip(file)
}

urls %>%
  iwalk(download_unzip)

