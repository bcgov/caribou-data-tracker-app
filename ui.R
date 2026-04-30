
# Define UI
fluidPage(
  titlePanel("Caribou Data Tracker - Database Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Filter Options"),
      selectizeInput("serial", "Device serial(s):", choices = NULL, multiple = TRUE, options = list(placeholder = "Enter a device serial #")),
      selectizeInput("wlh_id", "WLH ID(s):", choices = NULL, multiple = TRUE, options = list(placeholder = "Enter WLH ID")),
      checkboxInput("filter_sims_devices", "Only show records missing from SIMS", FALSE), 
      actionButton("submit", "Search", class = "btn-primary"),
      actionButton("reset", "Reset"),
      h6("If entering both serial number and WLH ID, tables will be filtered using OR logic. (E.g., will show any records where device serial OR WLH ID match.)"),
      hr(),
      h4("Summary"),
      uiOutput("summary"),
      hr(),
      actionButton("refresh_sims_devices", "Refresh SIMS devices", class = "btn-primary"),
      width = 2
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

