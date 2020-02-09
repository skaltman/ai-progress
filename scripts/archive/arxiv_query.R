arxiv_request <-
  function(query, start, limit, batchsize, sleep = 0, timeout = 30, sep = "|") {

  url <- str_glue("http://export.arxiv.org/api/query")
  body <-
    list(
      search_query = query,
      start = start,
      max_results = limit,
      sortOrder = "ascending"
    )

  # batch if needed

  search_result <-
    try(
      httr::POST(
        url,
        body = body,
        httr::timeout(timeout)
      )
    )

  httr::stop_for_status(search_result)

  arxiv_as_tibble(search_result)
}

arxiv_sleep_then_batch <- function(
  query, start, limit, batchsize, batch_number, sleep, timeout = 30, sep = "|"
) {

  Sys.sleep(sleep)

  result <-
    arxiv_request(query, start, limit, batchsize, timeout = timeout, sep = sep)

  message("Retrieved batch ", batch_number)

  result
}


arxiv_batches <- function(
  query, start, limit, batchsize, sleep, sep = "|"
) {
  n_batch <- (limit %/% batchsize) + ifelse(limit %% batchsize, 1, 0)
  max_record <- start + limit - 1

  result <-
    tibble(
      start = seq(start, start + limit - 1, by = batchsize),
      limit =
        if_else(
          max_record - start + 1 < batchsize,
          max_record - start + 1,
          batchsize
        )
    ) %>%
    mutate(n = row_number()) %>%
    pmap_dfr(
      ~ arxiv_sleep_then_batch(
        query = query,
        start = ..1,
        limit = ..2,
        batchsize = batchsize,
        batch_number  = ..3,
        sleep = sleep,
        sep = sep
      )
    )

  result
}

arxiv_as_tibble <- function(search_result) {
  aRxiv:::result2list(search_result) %>%
    aRxiv:::get_entries() %>%
    aRxiv:::listresult2df(sep = sep) %>%
    as_tibble()
}
