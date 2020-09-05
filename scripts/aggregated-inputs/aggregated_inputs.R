# All aggregated inputs data

# Author: Sara Altman
# Version: 2020-09-03

# Libraries
library(tidyverse)
library(googlesheets4)

# Parameters
  # Sheet key
key <- "1BHzohNJ7Uu4Xr58T9YjKDLoCkaF-EDKcRtGlEjhOQFA"
  # Worksheet name
sheet_name <- "all_inputs"
  # Sheet ranges
range_factor_increase <- "A2:D13"
range_datasphere <- "F2:I41"
range_compute <- "L2:N22"

  # Output files
file_out_factor_increase <-
  here::here("data-raw/factor_increase.csv")
file_out_datasphere <-
  here::here("data-raw/funding.csv")
file_out_compute <-
  here::here("data-raw/compute.csv")
#===============================================================================

# Factor increase since 2009
# read_sheet(
#   ss = key,
#   sheet = sheet_name,
#   range = range_factor_increase
# ) %>%
#   drop_na(Year) %>%
#   janitor::clean_names() %>%
#   write_rds(file_out_factor_increase)

# Funding by year and datasphere size
# read_sheet(
#   ss = key,
#   sheet = sheet_name,
#   range = range_datasphere
# ) %>%
#   drop_na(Year) %>%
#   janitor::clean_names() %>%
#   write_csv(file_out_datasphere)

# Compute
read_sheet(
  ss = key,
  sheet = sheet_name,
  range = range_compute
) %>%
  janitor::clean_names() %>%
  write_rds(file_out_compute)


