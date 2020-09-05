# Read in Penn Treebank data from Google Sheets

# Author: Sara Altman
# Version: 2020-09-03

# Libraries
library(tidyverse)
library(googlesheets4)

# Parameters
  # Sheet key with data
key <- "1m-3VwqglJokvUKwBomrbeiQcn5pbCm1mJ37sh7DK6yM"
  # Maximum number of rows to read in
N_MAX <- 12
  # Output file
file_out <- here::here("data/aggregated-inputs/penn_treebank.rds")
#===============================================================================

read_sheet(
    ss = key,
    col_types = "cddcdddc",
    na = c("", "NA"),
    n_max = N_MAX
  ) %>%
  mutate(date = parse_date(date, format = "%m/%d/%y")) %>%
  write_rds(file_out)


