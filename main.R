source("scripts/import.r")
source("scripts/parameters.r")
# for illustrative purposes, an anonymized dataset will be used here
# files can be processed separately from each other
# raw parquet files are stored in data/raw/
paths <- get_data_paths(path = "data/raw", pattern = "\\.parquet$")

for (path in paths) {
  dt <- read_dt(path)
}
