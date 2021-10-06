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

      textOutput(outputId = 'remote_files_cache_timestamp'),

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

  # FIXME: Make cache info available initially
  reload_rfc <- eventReactive(input$reload_remote_files_cache, {
    x <- callr::r_bg(func = save_remote_files_cache,
                     supervise = TRUE)
    return(x)
  })
  # FIXME: Do not interrupt cache reloading after first invalidation period
  progress_of_reload_rfc <- reactive({
    invalidateLater(millis = 1000, session = session)

    if (reload_rfc()$is_alive()) {
      x <- 'Reloading cache...'
    } else {
      x <- as.character(cache_file_modified_time())
      x <- glue('Cache available from {x}')
    }
    return(x)
  })
  output$remote_files_cache_timestamp <- renderText({
    progress_of_reload_rfc()
  })

  # CLEANUP ----
  # TODO: Remove when deploying

  session$onSessionEnded(function() {stopApp()})

}

shinyApp(ui = ui, server = server)
