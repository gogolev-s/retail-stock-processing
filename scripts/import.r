library(arrow)
library(data.table)

get_data_paths <- function(path, pattern) {
  return(
    list.files(path = path,
               pattern = pattern,
               full.names = TRUE)
  )
}

read_dt <- function(path) {
  dt <- data.table(read_parquet(path, col_select = all_of(target_cols)))
  return(dt)
}
