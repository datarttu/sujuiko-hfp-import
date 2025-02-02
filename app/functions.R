library(dplyr)
library(stringr)
library(lubridate)
library(gdata)
library(AzureStor)
library(R.utils)

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
    select(name, date, hour, size_bytes = size)
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
        tibble(name = character(),
               date = Date(),
               hour = integer(),
               size_bytes = double())
      )
    }
  )
}

#' Get latest modification time information of cache file
#'
#' @param cache_file RDS cache file path
cache_file_modified_time_info <- function(cache_file = 'remote_files.rds') {
  x <- file.info(cache_file)$mtime
  if (is.na(x)) {
    return('Cache file not available')
  }
  x <- as.character(x)
  x <- glue::glue('Cache available from {x}')
  return(x)
}

#' Aggregate date-hour remote files tibble by date
#'
#' @param date_hour_tibble Tibble returned by `get_remote_files_cache()`.
remote_files_by_date <- function(date_hour_tibble) {
  x <- date_hour_tibble %>%
    group_by(date) %>%
    summarise(n_files = n(),
              total_bytes = sum(size_bytes, na.rm = TRUE)) %>%
    mutate(wday = wday(date, label = TRUE, week_start = 1, locale = 'fi_FI.UTF-8'),
           total_bytes_txt = gdata::humanReadable(total_bytes)) %>%
    select(wday, date, n_files, total_bytes_txt) %>%
    arrange(desc(date))
  return(x)
}

#' Get hourly remote files of given dates
#'
#' @param date_hour_tibble Tibble returned by `get_remote_files_cache()`.
#' @param dates Dates to get hourly rows from.
#'
#' @return A subset of `date_hour_tibble`.
hourly_files_of_dates <- function(date_hour_tibble, dates) {
  x <- date_hour_tibble %>%
    filter(date %in% dates) %>%
    mutate(bytes_txt = gdata::humanReadable(size_bytes)) %>%
    select(date, hour, bytes_txt)
  return(x)
}

#' Download and gzip hourly remote file
#' @param name File name inside the storage
#' @param storage_url Storage root URL
#' @param target_dir Target directory to save to
#' @param do_gzip Gzip the result file?
#'
#' @return Path of the file (invisibly)
download_hourly_file <- function(
  name,
  storage_url = CONFIG$storage_url,
  target_dir = CONFIG$local_raw_files_dir,
  do_gzip = TRUE
) {
  if (!(str_sub(storage_url, -1, -1) == '/')) {
    storage_url = paste0(storage_url, '/')
  }
  full_url <- paste0(storage_url, name)
  # For the local file, drop parent dirs from the name:
  name_parts <- str_split(name, '/')[[1]]
  name_last <- name_parts[length(name_parts)]
  destfile <- file.path(target_dir, name_last)
  download.file(url = full_url, destfile = destfile)
  if (do_gzip) {
    destfile <- R.utils::gzip(destfile)
  }
  invisible(destfile)
}

