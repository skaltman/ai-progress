# Counts of number of papers published in each subfield

# Author: Sara Altman
# Version: 2020-01-31

# Libraries
library(tidyverse)
library(aRxiv)
library(googlesheets4)

# Parameters
file_subfields <- here::here("data/subfields.rds")
file_out <- here::here("data/subfield_counts.rds")
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws_subfields <- "Subfield counts"
#===============================================================================

subfield_counts <-
  read_rds(file_subfields) %>%
  mutate(count = map_int(code, ~ arxiv_count(str_glue("cat:{.}"))))

subfield_counts %>%
  write_rds(file_out)

subfield_counts %>%
  sheets_write(sheet_key, sheet = ws_subfields)

