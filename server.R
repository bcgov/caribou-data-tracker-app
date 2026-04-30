# Define server logic
function(input, output, session) {
  # Reactive values to store results
  results <- reactiveValues(
    sims_devices = DBI::dbReadTable(conn, "sims_devices"),
    key_files = DBI::dbReadTable(conn, "key_files"),
    caribou_dat = DBI::dbReadTable(conn, "caribou_dat"),
    summary = NULL
  )
  
  
  
  # Query function
  query_database <- function() {
    serial_input <- input$serial
    wlh_id_input <- input$wlh_id
    filter_sims <- input$filter_sims_devices
    
    message("Serial input: ", serial_input)
    message("WLH ID input: ", wlh_id_input)
    message("Input logic: ", input_logic(serial_input, wlh_id_input))
    message("Filter SIMS: ", filter_sims)
    
    # Query sims_devices, key_files, and caribou_dat tables
    if (filter_sims) {
      # If we're filtering to only stuff MISSING from SIMS
      serials_in_sims <- DBI::dbGetQuery(conn, "select distinct(serial) from sims_devices;")
      results$sims_devices <- data.frame(message = "See other tabs to check devices missing from SIMS")
      results$key_files <- query_key_files(serial_input, wlh_id_input) |>
        dplyr::filter(!(serial %in% serials_in_sims))
      results$caribou_dat <- query_caribou_dat(serial_input, wlh_id_input) |>
        dplyr::filter(!(serial %in% serials_in_sims))
    } else {
      # Else including stuff that is already in SIMS
      results$sims_devices <- query_sims_devices(serial_input, wlh_id_input)
      results$key_files <- query_key_files(serial_input, wlh_id_input)
      results$caribou_dat <- query_caribou_dat(serial_input, wlh_id_input)
    }

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
    updateTextInput(session, "serial", value = "")
    updateTextInput(session, "wlh_id", value = "")
    updateCheckboxInput(session, "filter_sims_devices", value = FALSE)
    results$sims_devices <- DBI::dbReadTable(conn, "sims_devices")
    results$key_files <- DBI::dbReadTable(conn, "key_files")
    results$caribou_dat <- DBI::dbReadTable(conn, "caribou_dat")
    results$summary <- NULL
    message("Reset")
  }
  
  # Observe submit button
  observeEvent(input$submit, {
    query_database()
  })
  
  # Observe reset button
  observeEvent(input$reset, {
    reset_inputs()
  })
  
  # Observe SIMS refresh button
  observeEvent(input$refresh_sims_devices, {
    update_devices_table(params = params)
  })
  
  # Render tables
  output$sims_devices_table <- renderDT({
    if (is.null(results$sims_devices)) {
      return(data.frame())
    }
    results$sims_devices
  })
  
  output$key_files_table <- renderDT({
    if (is.null(results$key_files)) {
      return(data.frame())
    }
    results$key_files
  })
  
  output$caribou_dat_table <- renderDT({
    if (is.null(results$caribou_dat)) {
      return(data.frame())
    }
    results$caribou_dat
  })
  
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
