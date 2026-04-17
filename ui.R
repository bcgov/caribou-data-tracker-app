# Load required libraries
library(shiny)
library(DBI)
library(RSQLite)

# Define UI
ui <- fluidPage(
  titlePanel("Caribou Data Tracker - Database Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Filter Options"),
      textInput("device_id", "Device ID:", placeholder = "Enter device ID"),
      textInput("wlh_id", "WLH ID:", placeholder = "Enter WLH ID"),
      checkboxInput("filter_sims_devices", "Only show records in SIMS Devices table", FALSE),
      actionButton("submit", "Search", class = "btn-primary"),
      actionButton("reset", "Reset"),
      hr(),
      h4("Summary"),
      uiOutput("summary")
    ),
    
    mainPanel(
      h2("Query Results"),
      tabsetPanel(
        tabPanel("SIMS Devices", tableOutput("sims_devices_table")),
        tabPanel("Key Files", tableOutput("key_files_table")),
        tabPanel("Caribou Data", tableOutput("caribou_dat_table")),
        tabPanel("ID Presence Summary", tableOutput("summary_table"))
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  # Reactive values to store results
  results <- reactiveValues(
    sims_devices = NULL,
    key_files = NULL,
    caribou_dat = NULL,
    summary = NULL
  )
  
  # Connect to database
  conn <- dbConnect(RSQLite::SQLite(), dbname = "data/caribou-data-tracker-app-dat.db")
  
  # Query function
  query_database <- function() {
    device_id_input <- input$device_id
    wlh_id_input <- input$wlh_id
    filter_sims <- input$filter_sims_devices
    
    # If both inputs are empty, show message
    if (device_id_input == "" && wlh_id_input == "") {
      results$sims_devices <- data.frame(message = "Please enter a Device ID or WLH ID to search")
      results$key_files <- data.frame(message = "Please enter a Device ID or WLH ID to search")
      results$caribou_dat <- data.frame(message = "Please enter a Device ID or WLH ID to search")
      results$summary <- data.frame(message = "Please enter a Device ID or WLH ID to search")
      return()
    }
    
    # Query sims_devices table
    sims_query <- "SELECT * FROM sims_devices WHERE 1=1"
    if (device_id_input != "") {
      sims_query <- paste0(sims_query, " AND device_id = '", device_id_input, "'")
    }
    
    tryCatch({
      results$sims_devices <- dbGetQuery(conn, sims_query)
    }, error = function(e) {
      results$sims_devices <- data.frame(error = paste("Error querying sims_devices:", e$message))
    })
    
    # Query key_files table
    key_query <- "SELECT * FROM key_files WHERE 1=1"
    if (device_id_input != "") {
      key_query <- paste0(key_query, " AND device_id = '", device_id_input, "'")
    }
    
    tryCatch({
      results$key_files <- dbGetQuery(conn, key_query)
    }, error = function(e) {
      results$key_files <- data.frame(error = paste("Error querying key_files:", e$message))
    })
    
    # Query caribou_dat table
    caribou_query <- "SELECT * FROM caribou_dat WHERE 1=1"
    if (device_id_input != "") {
      caribou_query <- paste0(caribou_query, " AND device_id = '", device_id_input, "'")
    }
    if (wlh_id_input != "") {
      caribou_query <- paste0(caribou_query, " AND wlh_id = '", wlh_id_input, "'")
    }
    
    tryCatch({
      results$caribou_dat <- dbGetQuery(conn, caribou_query)
    }, error = function(e) {
      results$caribou_dat <- data.frame(error = paste("Error querying caribou_dat:", e$message))
    })
    
    # Create summary
    summary_data <- data.frame(
      Table = c("sims_devices", "key_files", "caribou_dat"),
      Records_Found = c(
        if (!is.null(results$sims_devices) && nrow(results$sims_devices) > 0) nrow(results$sims_devices) else 0,
        if (!is.null(results$key_files) && nrow(results$key_files) > 0) nrow(results$key_files) else 0,
        if (!is.null(results$caribou_dat) && nrow(results$caribou_dat) > 0) nrow(results$caribou_dat) else 0
      ),
      ID_Present = c(
        if (!is.null(results$sims_devices) && nrow(results$sims_devices) > 0) "Yes" else "No",
        if (!is.null(results$key_files) && nrow(results$key_files) > 0) "Yes" else "No",
        if (!is.null(results$caribou_dat) && nrow(results$caribou_dat) > 0) "Yes" else "No"
      )
    )
    results$summary <- summary_data
  }
  
  # Reset function
  reset_inputs <- function() {
    updateTextInput(session, "device_id", value = "")
    updateTextInput(session, "wlh_id", value = "")
    updateCheckboxInput(session, "filter_sims_devices", value = FALSE)
    results$sims_devices <- NULL
    results$key_files <- NULL
    results$caribou_dat <- NULL
    results$summary <- NULL
  }
  
  # Observe submit button
  observeEvent(input$submit, {
    query_database()
  })
  
  # Observe reset button
  observeEvent(input$reset, {
    reset_inputs()
  })
  
  # Render tables
  output$sims_devices_table <- renderTable({
    if (is.null(results$sims_devices)) {
      return(data.frame())
    }
    results$sims_devices
  }, striped = TRUE, hover = TRUE)
  
  output$key_files_table <- renderTable({
    if (is.null(results$key_files)) {
      return(data.frame())
    }
    results$key_files
  }, striped = TRUE, hover = TRUE)
  
  output$caribou_dat_table <- renderTable({
    if (is.null(results$caribou_dat)) {
      return(data.frame())
    }
    results$caribou_dat
  }, striped = TRUE, hover = TRUE)
  
  output$summary_table <- renderTable({
    if (is.null(results$summary)) {
      return(data.frame())
    }
    results$summary
  }, striped = TRUE, hover = TRUE)
  
  output$summary <- renderUI({
    if (is.null(results$summary)) {
      return(NULL)
    }
    summary_text <- paste(
      paste0("sims_devices: ", results$summary$ID_Present[1]),
      paste0("key_files: ", results$summary$ID_Present[2]),
      paste0("caribou_dat: ", results$summary$ID_Present[3]),
      sep = "\n"
    )
    pre(summary_text)
  })
  
  # Cleanup
  session$onSessionEnded(function() {
    dbDisconnect(conn)
  })
}

# Run the application
shinyApp(ui = ui, server = server)