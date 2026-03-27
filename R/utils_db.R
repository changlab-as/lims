# utils_db.R
# Raw database utility functions - no Shiny dependencies
# These functions work with explicit database connections
# The global pool object is available in the global environment for most use cases

# ── Database initialization ──────────────────────────────────────────────────

initialize_database <- function() {
  db_path <- "data/lims_db.sqlite"

  if (!dir.exists("data")) dir.create("data")

  con <- dbConnect(RSQLite::SQLite(), db_path)

  # Recreate Sites table to ensure schema is current
  dbExecute(con, "DROP TABLE IF EXISTS Sites")
  dbExecute(con, "
    CREATE TABLE Sites (
      site_id   TEXT PRIMARY KEY,
      site_name TEXT NOT NULL,
      site_lat  TEXT,
      site_long TEXT
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Plants (
      plant_id      TEXT PRIMARY KEY,
      site_id       TEXT NOT NULL,
      species       TEXT NOT NULL,
      health_status TEXT,
      fridge_loc    TEXT,
      date_created  DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Processing (
      proc_id      TEXT PRIMARY KEY,
      plant_id     TEXT NOT NULL,
      equipment_id TEXT,
      type         TEXT NOT NULL,
      date         DATETIME DEFAULT CURRENT_TIMESTAMP,
      technician   TEXT,
      notes        TEXT,
      FOREIGN KEY(plant_id) REFERENCES Plants(plant_id)
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Equipment (
      equipment_id   TEXT PRIMARY KEY,
      character_name TEXT NOT NULL,
      category       TEXT NOT NULL,
      description    TEXT,
      date_created   DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ")

  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS Labels (
      label_id         TEXT PRIMARY KEY,
      stage            INTEGER,
      site_id          TEXT,
      sample_type      TEXT,
      sample_id        TEXT,
      part_code        TEXT,
      part_id          TEXT,
      use_code         TEXT,
      sample_status    TEXT DEFAULT 'label_created',
      storage_location TEXT,
      collected_date   DATETIME,
      created_date     DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(site_id) REFERENCES Sites(site_id)
    )
  ")

  # Seed equipment data (Ghibli-named lab equipment)
  existing_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Equipment")
  if (existing_count$count[1] == 0) {
    equipment_data <- data.frame(
      equipment_id = c("U01", "Z01", "F01", "F02", "F03", "F04", "G01"),
      character_name = c(
        "Totoro, in B16-1",
        "Jiji, -30°C in R100",
        "Teto, 4C in R100",
        "Warawara, the large 2-door in the kitchen",
        "Ponyo, the small 2-door in my office",
        "Kodama, the fridge in the B05",
        "Laputa (Castle in the Sky)"
      ),
      category = c(
        "Ultra-Low Temperature (-80°C)",
        "Standard Freezers (-20°C to -30°C)",
        "Fridges (4C)", "Fridges (4C)", "Fridges (4C)", "Fridges (4C)",
        "Plant growth chamber"
      ),
      description = c(
        "Ultra-Low Freezer at -80C",
        "Freezer at -30C in R100",
        "Fridge at 4C in R100",
        "Large 2-door refrigerator in the kitchen",
        "Small 2-door refrigerator in my office",
        "Fridge in B05",
        "Plant growth chamber - Castle in the Sky"
      ),
      stringsAsFactors = FALSE
    )
    dbAppendTable(con, "Equipment", equipment_data)
  }

  dbDisconnect(con)
  return(db_path)
}

# ── Site database functions ──────────────────────────────────────────────────

fetch_site_by_id <- function(site_id, con) {
  dbGetQuery(con,
    "SELECT * FROM Sites WHERE site_id = ?",
    params = list(site_id))
}

fetch_all_sites <- function(con) {
  dbGetQuery(con,
    "SELECT site_id, site_name, site_lat, site_long FROM Sites ORDER BY site_id")
}

insert_site <- function(site_id, site_name, site_lat = NULL, site_long = NULL, con) {
  dbExecute(con,
    "INSERT INTO Sites (site_id, site_name, site_lat, site_long)
     VALUES (?, ?, ?, ?)",
    params = list(site_id, site_name, site_lat, site_long))
}

check_site_exists <- function(site_id, con) {
  result <- tryCatch({
    dbGetQuery(con,
      "SELECT COUNT(*) as count FROM Sites WHERE site_id = ?",
      params = list(site_id))
  }, error = function(e) {
    data.frame(count = 0)
  })
  if (nrow(result) > 0) result$count[1] > 0 else FALSE
}

# ── Sample/Plant database functions ──────────────────────────────────────────

fetch_samples_by_site <- function(site_id, con) {
  dbGetQuery(con,
    "SELECT * FROM Plants WHERE site_id = ? ORDER BY plant_id",
    params = list(site_id))
}

insert_sample <- function(plant_id, site_id, species, health_status = NA, fridge_loc = NA, con) {
  dbExecute(con,
    "INSERT INTO Plants (plant_id, site_id, species, health_status, fridge_loc)
     VALUES (?, ?, ?, ?, ?)",
    params = list(plant_id, site_id, species, health_status, fridge_loc))
}

# ── Label database functions ─────────────────────────────────────────────────

fetch_all_labels <- function(con) {
  dbGetQuery(con,
    "SELECT label_id, stage, site_id, sample_type, sample_id, sample_status
     FROM Labels ORDER BY created_date DESC LIMIT 100")
}

insert_label <- function(label_id, stage, site_id, sample_type, sample_id, con) {
  dbExecute(con,
    "INSERT INTO Labels (label_id, stage, site_id, sample_type, sample_id)
     VALUES (?, ?, ?, ?, ?)",
    params = list(label_id, stage, site_id, sample_type, sample_id))
}

# ── Sequential ID generators ─────────────────────────────────────────────────

generate_site_id <- function(con) {
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Sites")
  sprintf("ST%04d", result$count[1] + 1)
}

generate_plant_id <- function(site_id, con) {
  result <- dbGetQuery(con,
    "SELECT COUNT(*) as count FROM Plants WHERE site_id = ?",
    params = list(site_id))
  sprintf("%s-P%04d", site_id, result$count[1] + 1)
}

generate_proc_id <- function(con) {
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM Processing")
  sprintf("PROC%06d", result$count[1] + 1)
}

# ── Label PNG generation ─────────────────────────────────────────────────────

generate_label_png <- function(full_id, label_date, label_file) {
  # Generate QR code into a temporary square PNG
  set.seed(as.integer(charToRaw(full_id)) %% 2147483647)
  qr_obj    <- qr_code(full_id)
  temp_file <- tempfile(fileext = ".png")
  png(temp_file, width = 400, height = 400, bg = "white")
  plot(qr_obj)
  dev.off()
  qr_img <- png::readPNG(temp_file)

  # Compose final label
  png(label_file, width = 1800, height = 600, res = 150, bg = "white")
  grid.newpage()
  grid.text(full_id, x = 0.27, y = 0.75,
    gp = gpar(fontsize = 44, fontface = "bold", family = "monospace"),
    just = "centre")
  grid.text(as.character(label_date), x = 0.27, y = 0.25,
    gp = gpar(fontsize = 40, fontface = "bold", family = "monospace"),
    just = "centre")

  # QR code viewport — fixed square aspect ratio (right side of label)
  qr_vp <- viewport(x = 0.75, y = 0.5, width = 0.32, height = 0.96)
  pushViewport(qr_vp)
  grid.raster(qr_img, width = 0.9, height = 0.9, x = 0.5, y = 0.5)
  popViewport()
  dev.off()

  unlink(temp_file)
  invisible(label_file)
}
