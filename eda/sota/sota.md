SOTA
================
Sara Altman
2020-04-22

  - [Missing data and repeated
    benchmarks](#missing-data-and-repeated-benchmarks)
  - [Measurements by category](#measurements-by-category)
  - [Distinct tasks by category](#distinct-tasks-by-category)
  - [Percent change](#percent-change)

``` r
# Libraries
library(tidyverse)
library(lubridate)

# Parameters
file_sota <- here::here("data/sota/sota.rds")
file_sota_unfiltered <- here::here("data/sota/sota_unfiltered.rds")
#===============================================================================

sota <- 
  file_sota %>% 
  read_rds()

sota_unfiltered <-
  file_sota_unfiltered %>% 
  read_rds()
```

## Missing data and repeated benchmarks

The original data had 1498 measurements. However, many rows are missing
critical data, including the paper data, metric name, or metric value.

``` r
sota_unfiltered %>% 
  summarize_at(
    vars(paper_date, metric_name, metric_result), 
    list(missing = ~ sum(is.na(.)), percent = ~ sum(is.na(.)) / n() * 100)
  ) %>% 
  pivot_longer(
    cols = everything(), 
    names_to = c("variable", "measure"),
    names_pattern = "(.*)_(\\w+$)",
    values_to = "value"
  ) %>% 
  pivot_wider(names_from = measure, values_from = value) %>% 
  rename(num_missing = missing, percent_missing = percent) %>% 
  arrange(desc(percent_missing))
```

    ## # A tibble: 3 x 3
    ##   variable      num_missing percent_missing
    ##   <chr>               <dbl>           <dbl>
    ## 1 paper_date            543            36.2
    ## 2 metric_result         516            34.4
    ## 3 metric_name           509            34.0

There are 548 rows where at least one of these variables is mising.

I removed these rows, since we can’t use them. There also should only be
one benchmark measurement per task/metric combination per day. However,
sometimes a paper is entered in the data multiple times, with one entry
per model put forward in the paper. We only want to keep the model that
performed the best.

For example, there are 10 measurement of Average Treatment Effect Error
on a causal inference task on one day.

``` r
sota_unfiltered %>%
  filter_at(
    vars(paper_date, metric_result, metric_name), 
    all_vars(!is.na(.))
  ) %>% 
  count(paper_date, task, metric_name, sort = TRUE) 
```

    ## # A tibble: 744 x 4
    ##    paper_date          task                    metric_name                     n
    ##    <dttm>              <chr>                   <chr>                       <int>
    ##  1 2016-06-13 00:00:00 Causal Inference        Average Treatment Effect E…    10
    ##  2 2018-03-18 00:00:00 Mortality Prediction    F1 score                        8
    ##  3 2018-03-18 00:00:00 Mortality Prediction    Precision                       8
    ##  4 2018-03-18 00:00:00 Mortality Prediction    Recall                          8
    ##  5 2018-11-19 00:00:00 Speech Recognition      Percentage error                8
    ##  6 2016-03-22 00:00:00 Word Sense Disambiguat… F1                              5
    ##  7 2018-06-01 00:00:00 Hypernym Discovery      MAP                             5
    ##  8 2018-06-01 00:00:00 Hypernym Discovery      MRR                             5
    ##  9 2018-06-01 00:00:00 Hypernym Discovery      P@5                             5
    ## 10 2019-10-23 00:00:00 Linguistic Acceptabili… Accuracy                        5
    ## # … with 734 more rows

``` r
sota_unfiltered %>% 
  filter(
    paper_date == ymd("2016-06-13"), 
    task == "Causal Inference",
    metric_name == "Average Treatment Effect Error"
  ) %>% 
  select(paper_date, paper_title, model_name)
```

    ## # A tibble: 10 x 3
    ##    paper_date          paper_title                        model_name            
    ##    <dttm>              <chr>                              <chr>                 
    ##  1 2016-06-13 00:00:00 Estimating individual treatment e… Counterfactual Regres…
    ##  2 2016-06-13 00:00:00 Estimating individual treatment e… TARNet                
    ##  3 2016-06-13 00:00:00 Estimating individual treatment e… OLS with separate reg…
    ##  4 2016-06-13 00:00:00 Estimating individual treatment e… BART                  
    ##  5 2016-06-13 00:00:00 Estimating individual treatment e… Causal Forest         
    ##  6 2016-06-13 00:00:00 Estimating individual treatment e… Balancing Neural Netw…
    ##  7 2016-06-13 00:00:00 Estimating individual treatment e… k-NN                  
    ##  8 2016-06-13 00:00:00 Estimating individual treatment e… Balancing Linear Regr…
    ##  9 2016-06-13 00:00:00 Estimating individual treatment e… OLS with treatments a…
    ## 10 2016-06-13 00:00:00 Estimating individual treatment e… Random Forest

These measurements are from different models from the same paper. It
might also be important to note that `paper_id` is *not* a unique
identifier. For example, this paper has 10 different values of
`paper_id`, one for each model.

In the final data, for each task-metric-day combination, I included only
the data from the best-performing model. This eliminates around 20% of
the data, leaving us with 744 data points.

## Measurements by category

``` r
observations <-
  sota %>% 
  drop_na(metric_name, metric_result) %>% 
  count(benchmark_id, metric_name, sort = TRUE)

observations %>% 
  ggplot(aes(n)) +
  geom_histogram(binwidth = 1) +
  labs(
    title = 
      "Distribution of the number of times a metric is measured for a task",
    subtitle = "Many metrics are measured only once"
  )
```

![](SOTA_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

``` r
percent_only_one <-
  observations %>% 
  count(one = n == 1, sort = TRUE) %>% 
  summarize(percent = n[one] / sum(n) * 100) %>% 
  pull(percent) %>% 
  format(digits = 5)
```

54.027% of metrics are measured only once, which means we can’t
understand their trend over time.

``` r
observations_by_category <-
  sota %>% 
  drop_na(metric_result, metric_name) %>% 
  unnest(cols = categories) %>% 
  group_by(categories) %>% 
  count(benchmark_id, metric_name, name = "num_observations") %>% 
  count(num_observations, sort = TRUE, name = "n") %>% 
  ungroup()


observations_by_category %>% 
  group_by(categories) %>% 
  summarize(
    prop_one = n[num_observations == 1] / sum(n),
    n_metrics = sum(n)
  ) %>% 
  mutate(categories = fct_reorder(categories, prop_one, .desc = TRUE)) %>% 
  ggplot(aes(prop_one, categories, size = n_metrics)) +
  geom_point() +
  scale_x_continuous(breaks = scales::breaks_width(0.1)) +
  labs(
    x = "Proportion of metrics with only a single observation",
    title = "Proportion of single observation metrics by category",
    subtitle = "Many metrics are only measured once",
    size = "Number of\ndistinct metrics"
  )
```

![](SOTA_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

Three categories–Knowledge Base, Audio, and Adversarial–only include
metrics with a single observation.

## Distinct tasks by category

``` r
sota %>% 
  unnest(cols = categories) %>% 
  distinct(categories, task) %>% 
  count(categories) %>% 
  mutate(categories = fct_reorder(categories, n)) %>%
  ggplot(aes(n, categories)) +
  geom_point() +
  scale_x_continuous(breaks = scales::breaks_width(width = 10)) +
  labs(
    title = "Number of distinct tasks by category, ",
    subtitle = "Computer vision and NLP have the most tasks"
  )
```

![](SOTA_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

## Percent change

There should be no negative percent change.

``` r
sota %>% 
  count(percent_change < 0, sort = TRUE) %>% 
  mutate(prop = n / sum(n))
```

    ## # A tibble: 2 x 3
    ##   `percent_change < 0`     n  prop
    ##   <lgl>                <int> <dbl>
    ## 1 FALSE                  656 0.882
    ## 2 TRUE                    88 0.118

11% are (currently) negative.

``` r
sota %>% 
  unnest(cols = categories) %>% 
  filter(percent_change < 0) %>% 
  count(categories, sort = TRUE) 
```

    ## # A tibble: 5 x 2
    ##   categories                      n
    ##   <chr>                       <int>
    ## 1 Computer Vision                62
    ## 2 Natural Language Processing    11
    ## 3 Speech                          8
    ## 4 Time Series                     6
    ## 5 Audio                           1

Most are in Computer Vision (which also has the most data).

``` r
sota %>% 
  filter(percent_change > 0) %>% 
  unnest(cols = categories) %>% 
  filter(categories != "Playing Games") %>% 
  mutate(
    categories = 
      fct_reorder(categories, percent_change, .desc = TRUE)
  ) %>% 
  ggplot(aes(categories, percent_change)) +
  geom_hline(yintercept = 0, size = 1.5, color = "white") +
  geom_boxplot() +
  scale_y_log10() +
  theme(axis.text.x = element_text(angle = 45))
```

    ## Warning: Transformation introduced infinite values in continuous y-axis

![](SOTA_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

``` r
computer_vision <-
  sota %>% 
  unnest(categories) %>%  
  filter(categories == "Computer Vision") %>% 
  group_by(task) %>% 
  filter(
    n() > 1,
    all(percent_change > 0)
  ) %>% 
  ungroup()

computer_vision %>% 
  count(task, sort = TRUE)
```

    ## # A tibble: 35 x 2
    ##    task                                        n
    ##    <chr>                                   <int>
    ##  1 Face Detection                             16
    ##  2 Action Recognition In Videos               14
    ##  3 Visual Question Answering                  11
    ##  4 Action Classification                      10
    ##  5 Face Verification                          10
    ##  6 Weakly Supervised Action Localization       8
    ##  7 Document Image Classification               4
    ##  8 Few-Shot Learning                           4
    ##  9 Image Inpainting                            4
    ## 10 Unsupervised Image-To-Image Translation     4
    ## # … with 25 more rows

``` r
computer_vision %>% 
  unite(col = "group_", metric_name, task, remove = FALSE) %>% 
  ggplot(aes(days_written_after_first_in_benchmark, percent_change, group = group_)) +
  geom_line(alpha = 0.5) 
```

![](SOTA_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->
