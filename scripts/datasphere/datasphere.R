# Global datasphere data

# Source: Statista/IDC

# Author: Sara Altman
# Version: 2020-11-16

# Libraries
library(tidyverse)

# Parameters
file_datasphere <- here::here("data-raw/datasphere.csv")
file_data_created <- here::here("data-raw/data_created.csv")

file_out_datasphere <- here::here("data/datasphere/datasphere.csv")
file_out_data_created <- here::here("data/datasphere/data_created.csv")
#===============================================================================

datasphere <-
  file_datasphere %>%
  read_csv(
    col_types =
      cols(
        year = col_double(),
        size = col_double(),
        measurement = col_character()
      )
  ) %>%
  write_rds(file_out_datasphere)

data_created <-
  file_data_created %>%
  read_csv(
    col_types =
      cols(
        year = col_double(),
        size = col_double()
      )
  ) %>%
  write_rds(file_out_data_created)




