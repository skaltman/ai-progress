2020-04-24

  - [Primary categories](#primary-categories)
  - [Is `id` unique?](#is-id-unique)
  - [Titles](#titles)

``` r
# Libraries
library(tidyverse)

# Parameters
file_papers <- here::here("data/arxiv/papers.rds")
file_subfield_counts <- here::here("data/arxiv/subfield_counts.rds")
#===============================================================================

papers <- read_rds(file_papers)
subfield_counts <- read_rds(file_subfield_counts)
```

## Primary categories

``` r
papers %>% 
  count(primary_category, sort = TRUE)
```

    ## # A tibble: 147 x 2
    ##    primary_category     n
    ##    <chr>            <int>
    ##  1 cs.CV            24612
    ##  2 cs.LG            21803
    ##  3 cs.CL            11952
    ##  4 cs.AI             9990
    ##  5 stat.ML           8789
    ##  6 cs.RO             5766
    ##  7 cs.NE             3350
    ##  8 cs.IR             1382
    ##  9 math.OC           1235
    ## 10 eess.IV           1122
    ## # … with 137 more rows

## Is `id` unique?

``` r
df <-
  papers %>% 
  mutate(
    authors = map_chr(authors, ~ str_c(sort(.), collapse = ", ")),
    categories = map_chr(categories, ~ str_c(sort(.), collapse = ", "))
  )

x <-
  df %>% 
  select(-query_id) %>% 
  count(!!!., sort = TRUE) 

n_distinct(x$id) == nrow(x)
```

    ## [1] TRUE

Yes. There are duplicates because some papers appear in multiple search
categories.

## Titles

Are titles unique identifiers?

``` r
n_distinct(papers$title) == n_distinct(papers$id)
```

    ## [1] TRUE
