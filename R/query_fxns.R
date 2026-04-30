
# Takes a string, removes whitespace, and splits 
# it apart along commas. Returns a character
# vector where each element is a single comma
# separated value.
clean_input <- function(input) {
  out <- gsub(" ", "", input)
  out <- trimws(unlist(strsplit(out, ",")))
  out <- toupper(out) # just to keep case consistent across the app
  return(out)
}

# Function to check the logic of the supplied inputs -
# were device serials supplied, WLH IDs supplied, or both?
input_logic <- function(input_serial, input_wlh_id) {
  serial_na_yn <- all(is.na(input_serial))
  wlh_na_yn <- all(is.na(input_wlh_id))
  
  # Use dplyr::case_when to sort out 
  out <- case_when(
    !serial_na_yn & !wlh_na_yn ~ "both",
    !serial_na_yn ~ "serials",
    !wlh_na_yn ~ "wlh_ids",
    TRUE ~ "neither" # despite my package ostensibly being up-to-date, the `.default` arg fails here.
  )
  
  return(out)
}

# Query the sims_devices table based upon the case found
# in `input_logic()`
query_sims_devices <- function(input_serial, input_wlh_id) {
  # First check what input_serial & input_wlh_id was supplied
  case <- input_logic(input_serial, input_wlh_id)
  
  # Clean up input strings
  input_serial <- clean_input(input_serial)
  input_wlh_id <- clean_input(input_wlh_id)
  
  # Build serial & wlh_id strings where supplied
  # Note `q = FALSE` is VERY important, otherwise it will use
  # 'fancy quotes' that the SQL won't know how to parse. 
  if (!all(is.na(input_serial))) input_serial <- paste(sQuote(input_serial, q = F), collapse = ", ")
  if (!all(is.na(input_wlh_id))) input_wlh_id <- paste(sQuote(input_wlh_id, q = F), collapse = ", ")
  
  # Build appropriate query for the sims_devices table
  dbQuery <- case_when(
    case == "both" ~ paste("select project_id, project_name, survey_id, survey_name, survey_focal_species, device_id, device_key, s.serial, device_make_id, model, comment from sims_devices s left join caribou_dat c on s.serial = c.serial where s.serial in (", input_serial, ") or c.wlh_id in (", input_wlh_id, ");"),
    case == "serials" ~ paste("select * from sims_devices where serial in (", input_serial, ");"),
    case == "wlh_ids" ~ paste("select project_id, project_name, survey_id, survey_name, survey_focal_species, device_id, device_key, s.serial, device_make_id, model, comment from sims_devices s left join caribou_dat c on s.serial = c.serial where c.wlh_id in (", input_wlh_id, ");"),
    case == "neither" ~ "select * from sims_devices;"
  )
  
  dat <- DBI::dbGetQuery(conn, dbQuery)
  
  return(dat)
}

query_key_files <- function(input_serial, input_wlh_id) {
  # First check what input_serial & input_wlh_id was supplied
  case <- input_logic(input_serial, input_wlh_id)
  
  # Clean up input strings
  input_serial <- clean_input(input_serial)
  input_wlh_id <- clean_input(input_wlh_id)
  
  # Build serial & wlh_id strings where supplied
  # Note `q = FALSE` is VERY important, otherwise it will use
  # 'fancy quotes' that the SQL won't know how to parse. 
  if (!all(is.na(input_serial))) input_serial <- paste(sQuote(input_serial, q = F), collapse = ", ")
  if (!all(is.na(input_wlh_id))) input_wlh_id <- paste(sQuote(input_wlh_id, q = F), collapse = ", ")
  
  # Build appropriate query for the key_files table
  dbQuery <- case_when(
    case == "both" ~ paste("select path, basename, type, k.serial from key_files k left join caribou_dat c on k.serial = c.serial where k.serial in (", input_serial, ") or c.wlh_id in (", input_wlh_id, ");"),
    case == "serials" ~ paste("select * from key_files where serial in (", input_serial, ");"),
    case == "wlh_ids" ~ paste("select path, basename, type, k.serial from key_files k left join caribou_dat c on k.serial = c.serial where c.wlh_id in (", input_wlh_id, ");"),
    case == "neither" ~ "select * from key_files;"
  )
  
  dat <- DBI::dbGetQuery(conn, dbQuery)
  
  return(dat)
}

query_caribou_dat <- function(input_serial, input_wlh_id) {
  # First check what input_serial & input_wlh_id was supplied
  case <- input_logic(input_serial, input_wlh_id)
  
  # Clean up input strings
  input_serial <- clean_input(input_serial)
  input_wlh_id <- clean_input(input_wlh_id)
  
  # Build serial & wlh_id strings where supplied
  # Note `q = FALSE` is VERY important, otherwise it will use
  # 'fancy quotes' that the SQL won't know how to parse. 
  if (!all(is.na(input_serial))) input_serial <- paste(sQuote(input_serial, q = F), collapse = ", ")
  if (!all(is.na(input_wlh_id))) input_wlh_id <- paste(sQuote(input_wlh_id, q = F), collapse = ", ")
  
  # Build appropriate query for the key_files table
  dbQuery <- case_when(
    case == "both" ~ paste("select * from caribou_dat where serial in (", input_serial, ") or wlh_id in (", input_wlh_id, ");"),
    case == "serials" ~ paste("select * from caribou_dat where serial in (", input_serial, ");"),
    case == "wlh_ids" ~ paste("select * from caribou_dat where wlh_id in (", input_wlh_id, ");"),
    case == "neither" ~ "select * from caribou_dat;"
  )
  
  dat <- DBI::dbGetQuery(conn, dbQuery)
  
  return(dat)
}

