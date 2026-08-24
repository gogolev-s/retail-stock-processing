# Set of columns used as a primary key
id_cols <- c("product_id", "store_id", "discount_type", "ts")

# Columns in the files
target_cols <- c(
  "ts", "product_id", "product_name", "category",
  "store_id", "stock", "price_old", "price_new",
  "discount_type", "discount_value", "expiration_date"
)

# Columns that should be numeric
num_cols <- c("stock", "price_old", "price_new", "discount_value")

# Quality check status is determined by the thresholds. The direction indicates
# whether the value is restricted by a "max" or "min" threshold. For example,
# "max" means that the values are acceptable up to acceptable_threshold
# and critical above critical_threshold.

# Expected number of 15-minute observations in a 16-hours working day
expected_hours <- 16
expected_time_points <- 4 * expected_hours
quality_thresholds <- data.table(
  criterion = c(
    "Rows with NA in ID columns (%)",
    "Rows with NA in non-ID columns (%)",
    "Duplicate ID groups (count)",
    "Invalid expiration dates (%)",
    "Missing expiration dates (%)",
    "Products with time gaps (%)",
    "Average time gap length (hours)"
  ),
  acceptable_threshold = c(0, 0.5, 0, 0, 0, 0, 0), # TBD
  critical_threshold = c(0, 1, 0, 0, 0, 0, 0), # TBD
  direction = "max"
)

quality_thresholds <- rbind(
  quality_thresholds,
  rbindlist(lapply(num_cols, function(column) {
    data.table(
      criterion = c(
        paste0("Invalid numeric type (%) in ", column),
        paste0("Negative numeric values (%) in ", column),
        paste0("Missing numeric values (%) in ", column)
      ),
      acceptable_threshold = c(0.5, 0, 0.5), # TBD
      critical_threshold = c(1, 0, 1), # TBD
      direction = "max"
    )
  }))
)

quality_thresholds <- rbind(
  quality_thresholds,
  data.table(
    criterion = c("Row count", "Unique timestamps", "Distinct hours",
                  "Distinct products", "Distinct stores"),
    acceptable_threshold = c(0, expected_time_points, expected_hours,
                             500, 100), # TBD
    critical_threshold = c(0, expected_time_points * 0.9, expected_hours * 0.9,
                           100, 50), # TBD
    direction = "min"
  )
)
