# See 'global.R' for globally-defined params

# Create OAuth client to connect to SIMS
sims_client <- function() {
  httr2::oauth_client(
    id = "sims-4461",
    token_url = "https://loginproxy.gov.bc.ca/auth/realms/standard/protocol/openid-connect/token",
    name = "sims_oauth"
  )
}


# Build a SIMS API URL GET request
req_sims <- function(...) {
  # First, pull the secret redirectURI
  source("temp/secrets.R")
  
  # Build the base request URL
  req <- httr2::request("https://api-biohubbc.apps.silver.devops.gov.bc.ca") |>
    httr2::req_oauth_auth_code(client = sims_client(), 
                               auth_url = "https://loginproxy.gov.bc.ca/auth/realms/standard/protocol/openid-connect/auth",
                               redirect_uri = redirectURI # this is pulled from secrets.R
                               ) |>
    httr2::req_method("GET") |>
    httr2::req_headers(accept = "application/json")
  # Append any dots `...` args to the URL
  url_bits <- list(...)
  # Add the url_bits to the request URL
  req <- req |>
    httr2::req_url_path_append(url_bits)
  # Return
  return(req)
}

# Request all caribou telemetry projects
req_sims_projects <- function(params # vector of API params, e.g. `c(keyword = "bctw", itis_tsns = 180701, itis_tsns = 202411)`
                              # Note              c(keyword = "bctw", itis_tsns = 180701, itis_tsns = 202411)
                              # is equivalent to: c(keyword = "bctw", itis_tsns = c(180701, 202411))
                              ) {
  # Build request
  # /project/{projectId}
  req <- req_sims("project") |> # build our base SIMS request URL using the req_sims() fxn, then append 'project'
    httr2::req_url_query(!!!params, .multi = "explode") # then add our params to the end of the URL
    
  # GET response
  resp <- httr2::req_perform(req) |>
    httr2::resp_body_json()
  
  # Extract projects in tidy format
  projects <- tidyjson::spread_all(resp$projects)
  
  return(projects)
}

# Request surveys from a given projects list
req_sims_surveys <- function(projects # output from req_sims_projects
                             ) {
  
  # somewhere to catch all the surveys as we iterate through list of projects
  surveys_all <- vector("list", nrow(projects))
  
  # In theory there should be no duplicates here...
  project_ids <- projects$project_id
  
  # repeated queries to grab all surveys
  for (i in project_ids) {
    # Build request
    # /project/{projectId}/survey/
    req <- req_sims("project", i, "survey")
    
    # send request and process
    resp <- httr2::req_perform(req)
    json_data <- httr2::resp_body_json(resp)
    
    # list of 0 or more surveys associated with project
    surveys_i <- json_data$surveys
    
    # add results to surveys_all
    if (length(surveys_i) > 0) {
      surveys_df <- dplyr::bind_rows(surveys_i) # create a data frame
      surveys_df$project_id <- i # carry project id over
      surveys_df$project_name <- projects[["name"]][projects$project_id == i] # carry project name over
      surveys_all[[i]] <- surveys_df # and add result to running list of devices
    } else {
      surveys_all[[i]] <- NULL
    }
  }
  
  # Bind results together into a readable df
  surveys <- dplyr::bind_rows(surveys_all)
  
  return(surveys)
}

# Request devices from a given surveys list
req_sims_devices <- function(surveys) {

  # somewhere to catch all the devices as we iterate through list of surveys
  devices_all <- vector("list", nrow(surveys))
  
  # repeated queries to grab all devices
  for (i in seq_len(nrow(surveys))) {
    # Build request
    # /project/{projectId}/survey/{surveyId}/devices/
    req <- req_sims("project", 
                    surveys[["project_id"]][i],
                    "survey", 
                    surveys[["survey_id"]][i],
                    "devices")
    
    # send request and process
    resp <- httr2::req_perform(req)
    json_data <- httr2::resp_body_json(resp)
    
    # list of 0 or more devices associated with survey
    devices_i <- json_data$devices
    
    # add results to devices_all
    if (length(devices_i) > 0) {
      devices_df <- dplyr::bind_rows(devices_i) # create a data frame
      devices_df$project_id = surveys$project_id[i] # carry project id over
      devices_df$project_name = surveys$project_name[i]
      devices_df$survey_name = surveys$name[i]
      devices_df$survey_focal_species = surveys$focal_species[i]
      devices_all[[i]] <-devices_df # and add result to running list of devices
    } else {
      devices_all[[i]] <- NULL
    }
  }
  
  # Bind results together in a readable df
  devices <- dplyr::bind_rows(devices_all) |>
    dplyr::select(project_id,
           project_name,
           survey_id,
           survey_name,
           survey_focal_species,
           device_id,
           device_key,
           serial,
           device_make_id,
           model,
           comment) 
  
  devices$survey_focal_species <- unlist(devices$survey_focal_species)
  
  return(devices)
}


# And finally, a function to update the devices table
update_devices_table <- function(params) {
  
  # Pull projects
  message("Querying projects...")
  projects <- req_sims_projects(params)
  # Pull surveys
  message("Querying surveys...")
  surveys <- req_sims_surveys(projects)
  # Pull devices
  message("Querying devices...")
  devices <- req_sims_devices(surveys)
  
  # Connect to database
  message("Updating database table...")
  conn <- dbConnect(RSQLite::SQLite(), dbname = "data/caribou-data-tracker-app-dat.db")
  
  # Update devices table
  DBI::dbRemoveTable(conn, "sims_devices")
  DBI::dbWriteTable(conn, "sims_devices", devices, append = FALSE, overwrite = TRUE)
  
  # Disconnect from database
  DBI::dbDisconnect(conn)
  
  message("Done!")
  
}

