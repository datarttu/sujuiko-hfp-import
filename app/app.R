library(shiny)
library(DT)

# UI ----
ui <- fluidPage(

  fluidRow(

    column(
      width = 6,

      h1('Raw data available'),

      textOutput(outputId = 'raw_data_list_cache_timestamp'),

      actionButton(inputId = 'run_reload_data_list_cache',
                   label = 'Reload data list'),

      DTOutput(outputId = 'raw_data_days_table')
    ),

    column(
      width = 6,

      h1('Raw data of the selected day'),

      DTOutput(outputId = 'raw_files_of_day_table')
    )
  ),

  fluidRow(

    column(
      width = 6,

      h1('Route-dir-oday files'),

      DTOutput(outputId = 'rdo_files_table'),

      actionButton(inputId = 'run_normalize_rdo_files',
                   label = 'Normalize selected files')

    ),

    column(
      width = 6,

      h1('Normalized files'),

      DTOutput(outputId = 'normalized_files_table'),

      actionButton(inputId = 'run_copy_to_db',
                   label = 'Import selected files to database')

    )
  )
)

# SERVER ----
server <- function(input, output, session) {


  # CLEANUP ----
  # TODO: Remove when deploying

  session$onSessionEnded(function() {stopApp()})

}

shinyApp(ui = ui, server = server)
