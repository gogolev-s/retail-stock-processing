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