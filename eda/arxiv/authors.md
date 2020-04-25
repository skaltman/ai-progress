arXiv authors
================
Sara Altman
2020-02-08

``` r
library(tidyverse)

authors <- read_rds(here::here("data/arxiv/arxiv_authors.rds"))
```

``` r
authors %>% 
  mutate_all(is.na) %>% 
  count(!!!.)
```

    ## # A tibble: 1 x 5
    ##   id    submitted author query_id      n
    ##   <lgl> <lgl>     <lgl>  <lgl>     <int>
    ## 1 FALSE FALSE     FALSE  FALSE    379139

There are no NAs.

``` r
unique_authors <-
  authors %>% 
  count(author, sort = TRUE)

unique_authors
```

    ## # A tibble: 138,987 x 2
    ##    author               n
    ##    <chr>            <int>
    ##  1 Yoshua Bengio      310
    ##  2 Chunhua Shen       208
    ##  3 Sergey Levine      206
    ##  4 Dacheng Tao        176
    ##  5 Damien Chablat     171
    ##  6 Uwe Aickelin       170
    ##  7 Pieter Abbeel      159
    ##  8 Yang Liu           156
    ##  9 Michael I Jordan   155
    ## 10 Luc Van Gool       136
    ## # … with 138,977 more rows

According to this, there are 138987.

``` r
unique_authors %>% 
  arrange(author)
```

    ## # A tibble: 138,987 x 2
    ##    author               n
    ##    <chr>            <int>
    ##  1 A A Akinduko         1
    ##  2 A A Alharbiy         1
    ##  3 A A Arymurthy        1
    ##  4 A A Beheshti         1
    ##  5 A A Calderón         1
    ##  6 A A Delorey          1
    ##  7 A A Fadeeva          1
    ##  8 A A Frolov           1
    ##  9 A A Karazeev         1
    ## 10 A A Krizhanovsky     3
    ## # … with 138,977 more rows

There are still some that seem like they might be coded differently
elsewhere.

``` r
authors_entry <-
  authors %>% 
  group_by(author) %>% 
  top_n(n = -1, wt = submitted) %>% 
  ungroup() %>% 
  distinct(author, submitted) %>% 
  count(submitted, name = "new_authors") %>% 
  arrange(submitted) %>% 
  mutate(num_authors = cumsum(new_authors))

authors_entry %>% 
  rename(total_authors = num_authors)
```

    ## # A tibble: 5,391 x 3
    ##    submitted  new_authors total_authors
    ##    <date>           <int>         <int>
    ##  1 1993-08-01           2             2
    ##  2 1993-09-01           2             4
    ##  3 1993-11-01           5             9
    ##  4 1993-12-01           3            12
    ##  5 1994-01-01           1            13
    ##  6 1994-02-01           6            19
    ##  7 1994-03-01           2            21
    ##  8 1994-06-01           3            24
    ##  9 1994-08-01           9            33
    ## 10 1994-09-01           2            35
    ## # … with 5,381 more rows
