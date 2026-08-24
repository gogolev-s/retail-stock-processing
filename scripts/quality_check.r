library(data.table)
library(lubridate)

check_missing_values <- function(dt, id_cols) {
  non_id_cols <- setdiff(names(dt), id_cols)
  na_id <- dt[any(is.na(.SD)), .SD, .SDcols = id_cols][, .N]
  na_non_id <- dt[any(is.na(.SD)), .SD, .SDcols = non_id_cols][, .N]

  return(
    data.table(
      criterion = c("Rows with NA in ID columns (%)",
                    "Rows with NA in non-ID columns (%)"),
      value = c(na_id / nrow(dt) * 100, na_non_id / nrow(dt) * 100)
    )
  )
}

check_uniqueness <- function(dt, id_cols) {
  duplicates <- dt[, .N, by = id_cols][N > 1, .N]
  return(
    data.table(
      criterion = "Duplicate ID groups (count)",
      value = duplicates
    )
  )
}

check_numerical_validity <- function(dt, col) {
  values <- dt[[col]]
  numeric_values <- suppressWarnings(as.numeric(as.character(values)))
  non_convertible <- !is.na(values) & is.na(numeric_values)
  return(
    data.table(
      criterion = c(
        paste0("Invalid numeric type (%) in ", col),
        paste0("Negative numeric values (%) in ", col),
        paste0("Missing numeric values (%) in ", col)
      ),
      value = c(
        mean(non_convertible) * 100,
        mean(numeric_values < 0, na.rm = TRUE) * 100,
        mean(is.na(values)) * 100
      )
    )
  )
}

check_dates_validity <- function(dt) {
  # The code assumes each file contains data for a single date
  dt[, date := as.Date(ts)]
  if (length(unique(dt[, date])) > 1) {
    stop("File contains multiple dates: ", sort(unique(dt[, date])))
  }
  dt[, expiration_date := as.Date(expiration_date)]
  return(
    data.table(
      criterion = c("Missing expiration dates (%)",
                    "Invalid expiration dates (%)"),
      value = c(
        dt[is.na(expiration_date), .N] / nrow(dt) * 100,
        dt[date > expiration_date, .N] / nrow(dt) * 100
      )
    )
  )
}

check_time_continuity <- function(dt, gap_min = 60 * 3) {
  # Within a day, product stock should be recorded at regular intervals.
  # It cannot increase over time, and it should not be missing for long periods.
  # Due to the specific of the data collection process, it can be so that
  # at some moments not all products in a given store are recorded.
  # It becomes a problem if the gaps are too long.

  # TBD: Share of products with time gaps (e.g., more than 3 hours)
  # in their stock records and average time gap length for those products
  return(
    data.table(
      criterion = c("Products with time gaps (%)",
                    "Average time gap length (hours)"),
      value = c(0, 0)
    )
  )
}

check_metadata <- function(dt) {
  return(
    data.table(
      criterion = c("Row count", "Unique timestamps", "Distinct hours",
                    "Distinct products", "Distinct stores"),
      value = c(nrow(dt), dt[, uniqueN(ts)], dt[, uniqueN(hour(ts))],
        dt[, uniqueN(product_id)], dt[, uniqueN(store_id)]
      )
    )
  )
}

get_metadata <- function(dt) {
  return(
    data.table(
      date = first(dt[, as.Date(ts)]),
      hours = list(sort(dt[, unique(hour(ts))])),
    )
  )
}

classify_quality <- function(metrics, thresholds) {
  report <- merge(metrics, thresholds, by = "criterion", all.x = TRUE)
  report[,
         status := fifelse(
           direction == "max",
           fifelse(value > critical_threshold, "critical",
                   fifelse(value > acceptable_threshold, "dangerous", "ok")),
           fifelse(value < critical_threshold, "critical",
                   fifelse(value < acceptable_threshold, "dangerous", "ok"))
         )]
  setcolorder(report, c("criterion", "value", "acceptable_threshold",
                        "critical_threshold", "direction", "status"))
  return(report)
}

quality_summary <- function(dt, id_cols, num_cols, thresholds) {
  checks <- c(
    list(
      check_missing_values(dt, id_cols),
      check_uniqueness(dt, id_cols),
      check_dates_validity(dt),
      check_time_continuity(dt),
      check_metadata(dt)
    ),
    lapply(num_cols, function(col) check_numerical_validity(dt, col))
  )
  metrics <- rbindlist(checks, use.names = TRUE)
  return(classify_quality(metrics, thresholds))
}
