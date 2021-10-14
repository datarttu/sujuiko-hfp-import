library(shiny)
library(DT)
library(callr)
library(glue)
library(magrittr)

source('functions.R')

# UI ----
ui <- fluidPage(

  fluidRow(

    column(
      width = 6,

      h1('Raw data available'),

      tags$div(textOutput(outputId = 'remote_files_cache_info'),
               style = 'display:inline-block'),

      tags$div(actionButton(inputId = 'reload_remote_files_cache',
                            label = 'Reload remote data cache'),
               style = 'display:inline-block'),

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

  # Remote files ----
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

  rf_date <- reactive({
    dt <- remote_files_cache$data
    dt <- remote_files_by_date(dt)
    return(dt)
  })
  rf_date_DT <- reactive({
    x <- DT::datatable(
      rf_date(),
      colnames = c('Weekday', 'Date', 'Files', 'Total size'),
      extensions = 'Scroller',
      options = list(scrollY = 200, deferRender = TRUE, scroller = TRUE,
                     # Show table + column filters, no general search:
                     dom = 't'),
      filter = list(position = 'top'),
      selection = 'single'
    )
    return(x)
  })
  output$raw_data_days_table <- DT::renderDT(rf_date_DT())

  # Hourly files by sel. date ----
  rf_hour <- reactive({
    req(remote_files_cache$data,
        rf_date(),
        input$raw_data_days_table_rows_selected)
    hourly_dt <- hourly_files_of_dates(
      date_hour_tibble = remote_files_cache$data,
      # Date values from the active (clicked) rows in the per-date table:
      dates = rf_date()[input$raw_data_days_table_rows_selected, ]$date
    )
    return(hourly_dt)
  })
  rf_hour_DT <- reactive({
    x <- DT::datatable(
      rf_hour(),
      colnames = c('Date', 'Hour', 'File size'),
      extensions = 'Scroller',
      options = list(scrollY = 200, deferRender = TRUE, scroller = TRUE,
                     # Show table + column filters, no general search:
                     dom = 't'),
      filter = list(position = 'top')
    )
    return(x)
  })
  output$raw_files_of_day_table <- DT::renderDT(rf_hour_DT())

  # CLEANUP ----
  # TODO: Remove when deploying

  session$onSessionEnded(function() {stopApp()})

}

shinyApp(ui = ui, server = server)
