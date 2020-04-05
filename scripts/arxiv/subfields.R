# Subfield codes

# Author: Sara Altman
# Version: 2020-01-31

# Libraries
library(tidyverse)

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
sheet_key <- "1B-aG5p-Ro4aPMIkaK7CDKoDSVHEn9PuDAzRS3rpQCnE"
ws <- "Subfields"
file_out <- here::here("data/subfields.rds")
#===============================================================================

subfields %>%
  write_rds(file_out)

subfields %>%
  sheets_write(ss = sheet_key, sheet = ws)
