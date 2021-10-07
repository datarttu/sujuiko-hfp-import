library(shiny)
library(DT)
library(callr)
library(glue)

source('functions.R')

# UI ----
ui <- fluidPage(

  fluidRow(

    column(
      width = 6,

      h1('Raw data available'),

      textOutput(outputId = 'remote_files_cache_info'),

      actionButton(inputId = 'reload_remote_files_cache',
                   label = 'Reload remote data cache'),

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

  remote_files_cache <- reactiveValues(
    info = cache_file_modified_time_info(),
    data = get_remote_files_cache()
  )
  output$remote_files_cache_info <- renderText({
    remote_files_cache$info
  })
  # TODO: Run cache reload in background
  observeEvent(input$reload_remote_files_cache, {
    withProgress({
      save_remote_files_cache()
      remote_files_cache$info <- cache_file_modified_time_info()
      remote_files_cache$data <- get_remote_files_cache()
    }, message = 'Reloading file list from storage...')
  })

  # CLEANUP ----
  # TODO: Remove when deploying

  session$onSessionEnded(function() {stopApp()})

}

shinyApp(ui = ui, server = server)
