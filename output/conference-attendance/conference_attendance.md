Conference attendees
================
2020-12-04

  - [Attendance at large conferences](#attendance-at-large-conferences)
      - [Attendace at small
        conferences](#attendace-at-small-conferences)
  - [Conference attendance over time](#conference-attendance-over-time)

``` r
# Libraries
library(tidyverse)

file_conference_attendance <- 
  here::here("data/conference-attendance/conference_attendance.rds")

#===============================================================================
conference_attendance <-
  file_conference_attendance %>% 
  read_rds()
```

## Attendance at large conferences

``` r
attendance_plot <- function(size_, y_breaks, ...) {
  conference_attendance %>% 
  filter(
    size == size_,
    ...
  ) %>% 
  drop_na(attendance) %>% 
  mutate(conference = fct_reorder2(conference, year, attendance)) %>% 
  ggplot(aes(year, attendance, color = conference)) +
  geom_line() +
  scale_x_continuous(breaks = scales::breaks_width(5)) +
  scale_y_continuous(breaks = scales::breaks_width(y_breaks)) +
  labs(
    x = NULL,
    y = "Number of attendees",
    color = NULL,
    title = str_glue("Attendance at {str_to_lower(size_)} conferences"),
    caption = "Source: Conferences provided data"
  )
}

attendance_plot("Large", 5000) +
  labs(subtitle = "1984-2018")
```

![](conference_attendance_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

### Attendace at small conferences

``` r
attendance_plot("Small", 1000, year >= 1995) +
  labs(subtitle = "1995-2018")
```

![](conference_attendance_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

## Conference attendance over time

``` r
conference_attendance %>%  
  count(size, year, wt = attendance, name = "attendance") %>% 
  bind_rows(
    count(., year, wt = attendance, name = "attendance") %>% 
      mutate(size = "All conferences")
  ) %>% 
  arrange(size) %>% 
  ggplot(aes(year, attendance, color = size)) +
  geom_line() +
  geom_point(size = 1) +
  scale_x_continuous(breaks = scales::breaks_width(5)) +
  labs(
    x = NULL,
    y = "Number of  attendees",
    color = NULL,
    title = "AI conference attendance over time",
    caption = "Source: Conferences provided data"
  ) +
  theme(legend.position = "top")
```

![](conference_attendance_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->
