library(dplyr)
library(stringr)
library(lubridate)

CONFIG <- config::get(file = 'config.yml')

# Remote file information & caching ----

#' Get remote file information
#'
#' @param blob_prefix Blob prefix (character)
#'
#' @return A tibble of files and metadata available
get_remote_files_list <- function(blob_prefix = CONFIG$blob_prefix) {
  cont <- AzureStor::storage_container(CONFIG$storage_url)
  files <- AzureStor::list_blobs(cont, dir = CONFIG$blob_prefix)
  dt_hr <- as_tibble(files) %>%
    mutate(date_hr = str_extract(name, glue('(?<={CONFIG$blob_prefix}).+(?=.csv)'))) %>%
    mutate(date = as.Date(str_extract(date_hr, '[0-9]{4}-[0-9]{2}-[0-9]{2}')),
           hour = as.integer(str_sub(date_hr, -2, -1))) %>%
    # We expect data only from 2020 on, older timestamps are considered errors.
    filter(year(date) > 2019) %>%
    select(date, hour, size_bytes = size)
  return(dt_hr)
}


#' Fetch and save latest remote file information to cache file
#'
#' @param blob_prefix Blob prefix (character)
#' @param cache_file RDS cache file path to save to (character)
save_remote_files_cache <- function(blob_prefix = CONFIG$blob_prefix,
                                    cache_file = 'remote_files.rds') {
  message(glue::glue('Fetching remote file info from {blob_prefix} ...'))
  tryCatch(
    {
      dt <- get_remote_files_list(blob_prefix = blob_prefix)
      # There should be at least this many datasets available from 4/2020 to 9/2021...
      stopifnot(nrow(dt) > 12000)
      saveRDS(dt, file = cache_file)
      message(glue::glue('{nrow(dt)} file metadata rows saved to {cache_file}'))
    },
    error = function(e) {
      msg <- glue::glue('{e}\n(Cache file not saved)')
      # TODO: Should not use warning for fatal errors such as missing pkgs
      warning(msg)
    }
  )
}

#' Get latest remote file information from cache file
#'
#' @param cache_file RDS cache file path to read from (character)
get_remote_files_cache <- function(cache_file = 'remote_files.rds') {
  tryCatch(
    {
      stopifnot(file.exists(cache_file))
      return(readRDS(cache_file))
    },
    error = function(e) {
      msg <- glue('Could not read cache:\n{e}')
      # TODO: Should not use warning for fatal errors such as missing pkgs
      warning(msg)
      return(
        tibble(date = Date(), hour = integer(), size_bytes = double())
      )
    }
  )
}

#' Get latest modification time of cache file
#'
#' @param cache_file RDS cache file path
cache_file_modified_time <- function(cache_file = 'remote_files.rds') {
  return(file.info(cache_file)$mtime)
}
