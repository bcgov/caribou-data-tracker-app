

# Load required libraries
library(shiny)
library(DBI)
library(RSQLite)
library(DT)


# Global params -----------------------------------------------------------

# Base API URL; all requests will be built off this root

# For now these are hard-coded into the functions as I don't 
# expect them to change much. Similar to MacGregor's sims R pkg

#requestURL <- "https://api-biohubbc.apps.silver.devops.gov.bc.ca"
#clientID <- "sims-4461"
#authURL <- "https://loginproxy.gov.bc.ca/auth/realms/standard/protocol/openid-connect/auth"
#tokenURL <- "https://loginproxy.gov.bc.ca/auth/realms/standard/protocol/openid-connect/token"

# Note that redirectURI is stored in temp/secrets.R.
# Just sourcing it via the function at the moment...
#source("temp/secrets.R")

# API params specific to this project
# The following are all ITIS TSNs that have been used to refer to 
# caribou as the focal species -- want to ensure we query for all 
# of these specifically so as to avoid returning non-caribou results
params <- c(keyword = "bctw",
            itis_tsns = c(180701, 202411, 625197, 180700))

message("Global params loaded:")
print(params)
