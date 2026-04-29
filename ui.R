
# Define UI
ui <- fluidPage(
  titlePanel("Caribou Data Tracker - Database Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Filter Options"),
      textInput("serial", "Device serial:", placeholder = "Enter device serial #"),
      textInput("wlh_id", "WLH ID:", placeholder = "Enter WLH ID"),
      checkboxInput("filter_sims_devices", "Only show records in SIMS Devices table", FALSE), # TODO: inverse this
      actionButton("submit", "Search", class = "btn-primary"),
      actionButton("reset", "Reset"),
      hr(),
      h4("Summary"),
      uiOutput("summary"),
      hr(),
      actionButton("refresh_sims_devices", "Refresh SIMS devices", class = "btn-primary")
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

