Examine nested SOTA data
================
2020-04-24

  - [What does each row represent?](#what-does-each-row-represent)
  - [Missing values](#missing-values)
  - [Metrics](#metrics)
  - [Benchmarks](#benchmarks)
  - [Categories](#categories)
  - [Tasks](#tasks)
  - [Benchmarks](#benchmarks-1)
  - [Metrics](#metrics-1)

``` r
# Libraries
library(tidyverse)

# Parameters
file_sota <- here::here("data/sota/sota_nested.rds")
#===============================================================================

sota <- read_rds(file_sota)
```

## What does each row represent?

One paper can have multiple rows.

``` r
sota %>% 
  count(paper_id, benchmark_id, sort = TRUE)
```

    ## # A tibble: 1,217 x 3
    ##    paper_id benchmark_id     n
    ##       <dbl>        <dbl> <int>
    ##  1      377          226     6
    ##  2      378          226     6
    ##  3      379          226     6
    ##  4      380          226     6
    ##  5     1001          599     5
    ##  6     1002          599     5
    ##  7     1003          599     5
    ##  8     1004          599     5
    ##  9     1005          599     5
    ## 10      125           72     4
    ## # … with 1,207 more rows

One paper/model combo can also have multiple rows.

``` r
sota %>% 
  count(paper_id, model_name, sort = TRUE)
```

    ## # A tibble: 1,217 x 3
    ##    paper_id model_name                       n
    ##       <dbl> <chr>                        <int>
    ##  1      377 DNN                              6
    ##  2      378 4th year cardiology resident     6
    ##  3      379 5th year medical student         6
    ##  4      380 3rd year emergency resident      6
    ##  5     1001 DGC-Net aff+tps+homo             5
    ##  6     1002 PWC-Net                          5
    ##  7     1003 DeepMatching*                    5
    ##  8     1004 FlowNet2                         5
    ##  9     1005 SPyNet                           5
    ## 10      125 UMX                              4
    ## # … with 1,207 more rows

Each row represents a paper-metric combination.

``` r
sota %>% 
  select(index, paper_id, metric_name) %>% 
  unnest(cols = metric_name) %>% 
  count(paper_id, metric_name, sort = TRUE)
```

    ## # A tibble: 989 x 3
    ##    paper_id metric_name        n
    ##       <dbl> <chr>          <int>
    ##  1        0 Sequence error     1
    ##  2        1 Sequence error     1
    ##  3        2 Sequence error     1
    ##  4        3 Average PSNR       1
    ##  5        4 Average PSNR       1
    ##  6        8 RMSE               1
    ##  7        9 RMS                1
    ##  8       16 AUC                1
    ##  9       17 P@1                1
    ## 10       19 PSNR               1
    ## # … with 979 more rows

## Missing values

``` r
sota %>% 
  transmute_at(vars(benchmark_id, task), is.na) %>% 
  count(!!! .)
```

    ## # A tibble: 1 x 3
    ##   benchmark_id task      n
    ##   <lgl>        <lgl> <int>
    ## 1 FALSE        FALSE  1498

All rows have a benchmark ID and task

``` r
sota %>% 
  transmute_at(
    vars(metric_name, metric_result), 
    ~ map_lgl(., ~ is_empty(.))
  ) %>% 
  count(!!! ., sort = TRUE)
```

    ## # A tibble: 2 x 3
    ##   metric_name metric_result     n
    ##   <lgl>       <lgl>         <int>
    ## 1 FALSE       FALSE           989
    ## 2 TRUE        TRUE            509

There are 509 rows that are missing a `metric_name` and a
`metric_result`.

``` r
sota %>% 
  select(index, paper_id, metrics) %>% 
  unnest(cols = metrics) %>% 
  transmute_at(vars(metric, value), is.na) %>% 
  count(!!! .)
```

    ## # A tibble: 2 x 3
    ##   metric value     n
    ##   <lgl>  <lgl> <int>
    ## 1 FALSE  FALSE  1871
    ## 2 TRUE   TRUE    509

## Metrics

Are all metrics in the metrics tibble in the `metric_name` and
`metric_result` columns?

``` r
metrics_tibble_unnested <-
  sota %>% 
  select(index, paper_id, metrics) %>% 
  unnest(cols = metrics) %>% 
  distinct(paper_id, metric, value) %>% 
  filter(!is.na(metric), !is.na(value)) %>% 
  arrange(paper_id, metric)

metrics_lists_unnested <-
  sota %>% 
  select(paper_id, metric_name, metric_result) %>% 
  unnest(
    cols = c(metric_name, metric_result)
  ) %>% 
  rename(metric = metric_name, value = metric_result) %>% 
  arrange(paper_id, metric)

compare::compare(
  metrics_tibble_unnested, 
  metrics_lists_unnested
)
```

    ## FALSE [TRUE, FALSE, FALSE]

The number of paper-metric combinations is the same. The metrics in the
list columns of vectors (`metric_name` and `metric_result`) look like
they are cleaned up. They don’t have percentage signs, and some of the
numbers are converted from percentages to proportions.

Is every value in `metric_name` and `metric_result` a character vector
of length 1?

``` r
sota %>% 
  transmute_at(vars(metric_name, metric_result), ~ map_int(., length)) %>% 
  count(!!! .)
```

    ## # A tibble: 2 x 3
    ##   metric_name metric_result     n
    ##         <int>         <int> <int>
    ## 1           0             0   509
    ## 2           1             1   989

They are all either empty or length 1.

How many papers have no metrics?

``` r
number_of_metrics <-
  sota %>% 
  select(paper_id, metric_name, metric_result) %>% 
  unnest(cols = c(metric_name, metric_result), keep_empty = TRUE) %>% 
  group_by(paper_id) %>% 
  summarize(n_metrics = n_distinct(metric_name, na.rm = TRUE)) %>% 
  count(n_metrics, sort = TRUE)
```

There are 509 papers without a metric.

``` r
number_of_metrics %>% 
  ggplot(aes(n_metrics, weight = n)) +
  geom_bar() +
  scale_x_continuous(breaks = scales::breaks_width(1)) +
  labs(x = "Number of metrics per paper")
```

![](sota_nested_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

## Benchmarks

``` r
sota %>% 
  count(benchmark_id, sort = TRUE)
```

    ## # A tibble: 726 x 2
    ##    benchmark_id     n
    ##           <dbl> <int>
    ##  1          268    38
    ##  2          138    30
    ##  3          201    30
    ##  4          395    27
    ##  5          599    25
    ##  6           40    24
    ##  7          226    24
    ##  8          687    24
    ##  9           29    19
    ## 10          197    19
    ## # … with 716 more rows

## Categories

``` r
sota %>% 
  mutate(n_categories = map_int(categories, length)) %>% 
  count(n_categories, sort = TRUE)
```

    ## # A tibble: 3 x 2
    ##   n_categories     n
    ##          <int> <int>
    ## 1            1  1453
    ## 2            2    40
    ## 3            3     5

## Tasks

``` r
sota %>% 
  count(task, sort = TRUE)
```

    ## # A tibble: 726 x 2
    ##    task                                      n
    ##    <chr>                                 <int>
    ##  1 Ad-Hoc Information Retrieval             38
    ##  2 Dependency Parsing                       30
    ##  3 Language Modelling                       30
    ##  4 Text Summarization                       27
    ##  5 Dense Pixel Correspondence Estimation    25
    ##  6 ECG Classification                       24
    ##  7 Hypernym Discovery                       24
    ##  8 Mortality Prediction                     24
    ##  9 Semantic Textual Similarity              19
    ## 10 Speech Recognition                       19
    ## # … with 716 more rows

## Benchmarks

``` r
sota %>% 
  count(benchmark_id, sort = TRUE)
```

    ## # A tibble: 726 x 2
    ##    benchmark_id     n
    ##           <dbl> <int>
    ##  1          268    38
    ##  2          138    30
    ##  3          201    30
    ##  4          395    27
    ##  5          599    25
    ##  6           40    24
    ##  7          226    24
    ##  8          687    24
    ##  9           29    19
    ## 10          197    19
    ## # … with 716 more rows

## Metrics

Just look a speech recognition. Do they all have the same metric?

``` r
speech_recognition <-
  sota %>% 
  filter(task == "Speech Recognition") %>% 
  select(paper_id, model_name, paper_date, metrics) %>% 
  unnest(cols = metrics)

speech_recognition %>% 
  ggplot(aes(paper_date, value)) +
  geom_point()
```

    ## Warning: Removed 3 rows containing missing values (geom_point).

![](sota_nested_files/figure-gfm/unnamed-chunk-16-1.png)<!-- -->
