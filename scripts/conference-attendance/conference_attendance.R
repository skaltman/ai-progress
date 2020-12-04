# AI conference attendance data

# Author: Sara Altman
# Version: 2020-11-16

# Libraries
library(tidyverse)

# Parameters
file_in <-
  here::here("data-raw/conference_attendance.csv")
file_out <-
  here::here("data/conference-attendance/conference_attendance.rds")
#===============================================================================

conference_attendance <-
  file_in %>%
  read_csv(
    col_types =
      cols(
        conference = col_character(),
        size = col_character(),
        .default = col_double()
      )
  ) %>%
  pivot_longer(
    cols = -c(conference, size),
    names_to = "year",
    values_to = "attendance"
  ) %>%
  mutate(year = as.integer(year)) %>%
  write_rds(file_out)
