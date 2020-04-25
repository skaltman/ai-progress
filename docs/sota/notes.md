SOTA notes
================
2020-04-12

## Dataset: `sota.rds`

Each row represents a unique `paper_id`, `benchmark_id`, and
`metric_name` combination.

  - `index`:
  - `paper_id`: ID of the paper
  - `benchmark_id`: ID of the task
  - `categories`: A list column of categories (e.g., “Computer Vision”)
  - `task`: Name of the task (e.g., “Face Detection”)
  - `model_name`: Name of the model used in the paper to get the result
  - `paper_date`: Date paper was published
  - `paper_title`: Title of the paper
  - `metric_name`: Name of the metric (e.g., “Accuracy”)
  - `metric_result`: Metric result
  - `n_papers_in_benchmark`: Number of papers in the given benchmark.
  - `days_written_after_first_in_benchmark`: Number of days this paper
    was written after the first paper in the benchmark was published.
  - `minimze_metric`: Should this metric be minimized (e.g., is it an
    error metric?)?
  - `metric_standard`: The standardized version of `metric_result`. The
    error metrics and other metrics were `minimize_metric` is `TRUE` are
    coded as negative.
  - `percent_change`: Percent change in `metric_standard` since the last
    paper i n the data for the given task, metric name combination.

## Missing values

## Discarded data

  - The original data had around 30% NAs in `paper_date`, `metric_name`,
    and `metric_result`. I removed these rows.
  - The original data also often listed several results for the same
    metric on the same day. Often, these were the results from one paper
    with multiple models. Other times, they occurred because two papers
    happened to be published on the same day. I filtered the data to
    only include one result per `benchmark_id`-`metric_name` combination
    per day. This removed about half of the data left over after
    removing NAs.

There are three cases where the metric result was exactly the same.
Usually, this was a mistake (it looks like the same paper was entered
twice). I took the first one.

Also, important to note that `paper_id` is not a unique identifier of
the papers.
