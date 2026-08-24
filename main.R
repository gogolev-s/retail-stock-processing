source("scripts/import.r")
source("scripts/quality_check.r")
source("scripts/parameters.r")
# for illustrative purposes, an anonymized dataset will be used here
# files can be processed separately from each other
# raw parquet files are stored in data/raw/
paths <- get_data_paths(path = "data/raw", pattern = "\\.parquet$")
quality_reports <- list()
for (path in paths) {
  dt <- read_dt(path)
  quality_report <- quality_summary(dt, id_cols, num_cols, quality_thresholds)
  quality_reports[[path]] <- quality_report
}

# Show only failed quality checks ("dangerous" or "critical")
lapply(quality_reports, function(report) report[status != "ok"])
