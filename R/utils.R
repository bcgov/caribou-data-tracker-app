# Reset function
reset_inputs <- function(session) {
  updateTextInput(session, "serial", value = "")
  updateTextInput(session, "wlh_id", value = "")
  updateCheckboxInput(session, "filter_sims_devices", value = FALSE)
  results$sims_devices <- NULL
  results$key_files <- NULL
  results$caribou_dat <- NULL
  results$summary <- NULL
}