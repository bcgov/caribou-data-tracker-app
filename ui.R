
# Define UI
fluidPage(
  titlePanel("Caribou Data Tracker - Database Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Filter Options"),
      textInput("serial", "Device serial:", placeholder = "Enter device serial #"),
      textInput("wlh_id", "WLH ID:", placeholder = "Enter WLH ID"),
      #checkboxInput("filter_sims_devices", "Only show records missing from SIMS", FALSE), # TODO: inverse this
      actionButton("submit", "Search", class = "btn-primary"),
      #actionButton("reset", "Reset"),
      hr(),
      h4("Summary"),
      uiOutput("summary"),
      hr(),
      actionButton("refresh_sims_devices", "Refresh SIMS devices", class = "btn-primary")
    ),
    
    mainPanel(
      h2("Query Results"),
      tabsetPanel(
        tabPanel("SIMS Devices", DTOutput("sims_devices_table")),
        tabPanel("Key Files", DTOutput("key_files_table")),
        tabPanel("Caribou Data", DTOutput("caribou_dat_table")),
        tabPanel("ID Presence Summary", tableOutput("summary_table"))
      )
    )
  )
)

