#' Database Utility Functions
#' 
#' All database operations for LIMS, no Shiny dependencies
#' These functions work with explicit database connections
#'
#' @import DBI
#' @import RSQLite

#' Initialize Database
#'
#' @return Path to database file
#' @export
initialize_database <- function() {
  db_path <- "data/lims_db.sqlite"
  
  if (!dir.exists("data")) dir.create("data")
  
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  
  # Create Sites table
  DBI::dbExecute(con, "DROP TABLE IF EXISTS Sites")
  DBI::dbExecute(con, "
    CREATE TABLE Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")
  
  # Create Labels table
  DBI::dbExecute(con, "DROP TABLE IF EXISTS Labels")
  DBI::dbExecute(con, "
    CREATE TABLE Labels (
      label_id      TEXT PRIMARY KEY,
      stage         INTEGER,
      site_id       TEXT,
      sample_type   TEXT,
      sample_id     TEXT,
      sample_status TEXT DEFAULT 'label_created',
      created_date  DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
  
  # Create Batch Scans table
  DBI::dbExecute(con, "DROP TABLE IF EXISTS BatchScans")
  DBI::dbExecute(con, "
    CREATE TABLE BatchScans (
      scan_id       TEXT PRIMARY KEY,
      site_id       TEXT,
      sample_id     TEXT,
      scan_time     DATETIME DEFAULT CURRENT_TIMESTAMP,
      scanner_id    TEXT,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")
  
  DBI::dbDisconnect(con)
  return(db_path)
}

#' Fetch All Sites
#'
#' @param con Database connection
#' @return Data frame of all sites
#' @export
fetch_all_sites <- function(con) {
  DBI::dbGetQuery(con, "SELECT * FROM Sites")
}

#' Fetch Site by ID
#'
#' @param site_id Site identifier
#' @param con Database connection
#' @return Data frame with single site or empty if not found
#' @export
fetch_site_by_id <- function(site_id, con) {
  DBI::dbGetQuery(con, 
    "SELECT * FROM Sites WHERE site_id = ?",
    params = list(site_id)
  )
}

#' Insert Site
#'
#' @param site_id Site identifier
#' @param site_name Site name/description
#' @param con Database connection
#' @export
insert_site <- function(site_id, site_name, con) {
  DBI::dbExecute(con,
    "INSERT INTO Sites (site_id, site_name) VALUES (?, ?)",
    params = list(site_id, site_name)
  )
}

#' Check if Site Exists
#'
#' @param site_id Site identifier
#' @param con Database connection
#' @return Logical TRUE if exists
#' @export
check_site_exists <- function(site_id, con) {
  result <- DBI::dbGetQuery(con,
    "SELECT COUNT(*) as count FROM Sites WHERE site_id = ?",
    params = list(site_id)
  )
  result$count[1] > 0
}

#' Fetch All Labels
#'
#' @param con Database connection
#' @return Data frame of all labels
#' @export
fetch_all_labels <- function(con) {
  DBI::dbGetQuery(con, "SELECT * FROM Labels")
}

#' Insert Label
#'
#' @param label_id Label identifier
#' @param stage Processing stage
#' @param site_id Site identifier
#' @param sample_type Type of sample
#' @param sample_id Sample identifier
#' @param con Database connection
#' @export
insert_label <- function(label_id, stage, site_id, sample_type, sample_id, con) {
  DBI::dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id, sample_type, sample_id) 
     VALUES (?, ?, ?, ?, ?)",
    params = list(label_id, stage, site_id, sample_type, sample_id)
  )
}

#' Fetch All Batch Scans
#'
#' @param con Database connection
#' @return Data frame of all batch scans
#' @export
fetch_all_batch_scans <- function(con) {
  DBI::dbGetQuery(con, "
    SELECT bs.*, s.site_name 
    FROM BatchScans bs
    LEFT JOIN Sites s ON bs.site_id = s.site_id
    ORDER BY bs.scan_time DESC
  ")
}

#' Insert Batch Scan
#'
#' @param scan_id Scan identifier
#' @param site_id Site identifier
#' @param sample_id Sample identifier
#' @param scanner_id Scanner device ID
#' @param con Database connection
#' @export
insert_batch_scan <- function(scan_id, site_id, sample_id, scanner_id, con) {
  DBI::dbExecute(con,
    "INSERT INTO BatchScans (scan_id, site_id, sample_id, scanner_id) 
     VALUES (?, ?, ?, ?)",
    params = list(scan_id, site_id, sample_id, scanner_id)
  )
}

#' Generate Site ID
#'
#' @return Character string in format ST####
#' @export
generate_site_id <- function() {
  sprintf("ST%04d", sample(0:9999, 1))
}

#' Generate Plant ID
#'
#' @param site_id Site identifier
#' @return Character string in format P####
#' @export
generate_plant_id <- function(site_id) {
  sprintf("P%04d", sample(0:9999, 1))
}

#' Generate Processing ID
#'
#' @return Character string in format PR####
#' @export
generate_proc_id <- function() {
  sprintf("PR%04d", sample(0:9999, 1))
}

#' Generate Label PNG with QR Code
#'
#' @param label_id Label identifier
#' @param site_id Site identifier
#' @param sample_id Sample identifier
#' @param output_path Path to save PNG
#' @export
generate_label_png <- function(label_id, site_id, sample_id, output_path = "www/labels") {
  if (!dir.exists(output_path)) dir.create(output_path, recursive = TRUE)
  
  qr_data <- paste(label_id, site_id, sample_id, sep = "|")
  qr_code <- qrcode::qr_code(qr_data)
  
  png_path <- file.path(output_path, paste0(label_id, ".png"))
  
  png::writePNG(grid::rasterGrob(qr_code)$raster, png_path)
  
  return(png_path)
}

#' Validate Site ID Format
#'
#' @param site_id Site identifier to validate
#' @return Logical TRUE if valid
#' @export
validate_site_id <- function(site_id) {
  grepl("^ST\\d{4}$", site_id)
}

#' Validate Sample ID Format
#'
#' @param sample_id Sample identifier to validate
#' @return Logical TRUE if valid
#' @export
validate_sample_id <- function(sample_id) {
  !is.na(sample_id) && nzchar(trimws(sample_id))
}
