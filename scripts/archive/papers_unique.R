# Add unique papers to Google Sheets

# Author: Sara Altman
# Version: 2020-02-05

# Libraries
library(tidyverse)
library(googlesheets4)

# Parameters
file_papers <- here::here("data/papers.rds")
file_out <- here::here("data/papers_unique.rds")
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws <- "Papers"
#===============================================================================

papers_distinct <-
  read_rds(file_papers) %>%
  distinct(id, .keep_all = TRUE)

papers_distinct %>%
  write_rds(file_out)

papers_distinct %>%
  sheets_write(sheet_key, ws)
