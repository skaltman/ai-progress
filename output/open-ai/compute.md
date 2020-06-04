Compute
================
2020-05-31

  - [Overall PetaFlop vs. publication
    date](#overall-petaflop-vs.-publication-date)
  - [SOTA models: Overall PetaFlop vs. publication
    date](#sota-models-overall-petaflop-vs.-publication-date)

``` r
# Libraries
library(tidyverse)

# Parameters
file_compute <- here::here("data/open-ai/compute.csv")

file_compute_sota <- here::here("data/open-ai/compute_sota.csv")
#===============================================================================

compute <-
  file_compute %>% 
  read_csv()

compute_sota <-
  file_compute_sota %>% 
  read_csv()
```

## Overall PetaFlop vs. publication date

``` r
compute %>% 
  ggplot(aes(date, overall_petaflop_days)) +
  geom_point() +
  geom_line() +
  scale_x_datetime(date_breaks = "1 year", date_labels = "%b %Y") +
  scale_y_log10() +
  labs(
    x = "Publication date",
    y = "Overall PetaFlop Days",
    title = 
      "Overall PetaFlop Days vs. Publication Date"
  )
```

![](compute_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

## SOTA models: Overall PetaFlop vs. publication date

``` r
compute_sota %>% 
  ggplot(aes(date, overall_petaflop_days)) +
  geom_point() +
  geom_smooth(
    size = 0.5,
    method = "lm", 
    formula = 'y ~ x',
    se = FALSE
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%b %Y") +
  scale_y_log10(
    breaks = c(1e-4, 1e-2, 1, 100),
    labels = c("0.0001", "0.01", "1", "100")
  ) +
  labs(
    x = "Publication date",
    y = "Overall PetaFlop Days",
    title = "Compute used to power SOTA models",
    subtitle = "An exponential increase over the past decade"
  )
```

![](compute_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->
