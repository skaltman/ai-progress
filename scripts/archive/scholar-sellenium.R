# Use selenium to scrape google scholar

# Author: Name
# Version: 2020-02-22

# Libraries
library(tidyverse)
library(RSelenium)

# Parameters

#===============================================================================

remote_driver <-
  remoteDriver(
    remoteServerAddr = "localhost",
    port = 4567L,
    browserName = "safari"
  )

remote_driver$open()
