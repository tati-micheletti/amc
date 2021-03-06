if (getRversion() >= "3.1.0") {
  utils::globalVariables(".")
}

#' Load, save, and remove .RData objects
#'
#' Wrapper functions to \code{\link{load}}, \code{\link{save}},
#' and \code{\link{unlink}}, permitting lists of objects to be
#' loaded/saved/deleted all at once.
#'
#' By default, the extension \code{.RData} is used.
#'
#' @param  objects  A character list or character vector of object names
#'
#' @param  path     The filepath to the directory in which to save or
#'                  from which to load the objects. The path should be
#'                  constructed using \code{\link{file.path}}.
#'
#' @param  ext      The file extension to use (default is \code{.RData}).
#'
#' @param  quiet    Logical. Should output be suppressed? Default is \code{TRUE}.
#'
#' @param  envir    The environment in which to look for and load objects
#'                  (default: the environment from which the function was called).
#'
#' @return  Invisibly if \code{quiet=TRUE}. Either a list of objects loaded,
#'          empty list if saved, or if removed either \code{0} for success,
#'          \code{1} for failure.
#'
#' @seealso \code{\link{file.path}}, \code{\link{load}}, \code{\link{save}}, \code{\link{unlink}}
#'
#' @author Alex Chubaty
#' @export
#' @importFrom methods is
#' @importFrom raster brick filename raster stack
#' @rdname rdata-objects
#'
loadObjects <- function(objects, path = NULL, ext = ".RData", quiet = TRUE,
                        envir = parent.frame()) {
  if (is.null(path)) {
    path <- "."
  } else if (!dir.exists(path)) {
    stop(paste("Path", path, "does to exist."))
  }

  out <- lapply(objects, function(x) {
    load(file = file.path(path, paste0(x, ext)), envir = envir)

    ## if object is a raster, resave then reload it to make sure the x@file@name is correct
    if (is(get(x, envir = envir), "Raster")) {
      f <- filename(get(x, envir = envir)) %>% gsub("\\\\", "/", .)

      ## ensure rasters backed by files use the correct path for the current machine
      if (nzchar(f)) {
        r <- if (is(get(x, envir = envir), "RasterLayer")) {
          raster(file.path(path, basename(f)))
        } else if (is(get(x, envir = envir), "RasterStack")) {
          stack(file.path(path, basename(f)))
        } else if (is(get(x, envir = envir), "RasterBrick")) {
          brick(file.path(path, basename(f)))
        }
        assign(x, r, envir = envir)
        save(list = x, file = file.path(path, paste0(x, ext)))
        invisible(x) ## return character of object name, per '?load'
      }
    }
  })

  ifelse(quiet, return(invisible(out)), return(out))
}

#' @export
#' @rdname rdata-objects
saveObjects <- function(objects, path = NULL, ext = ".RData", quiet = TRUE,
                        envir = parent.frame()) {
  if (is.null(path)) path <- "."
  out <- lapply(objects, function(x) {
    assign(x, get(x, envir = envir))
    save(list = x, file = file.path(path, paste0(x, ext)))
  })
  ifelse(quiet, return(invisible(out)), return(out))
}

#' @export
#' @rdname rdata-objects
rmObjects <- function(objects, path = NULL, ext = ".RData", quiet = TRUE) {
  if (is.null(path)) path <- "."

  # delete the .RData files
  files <- lapply(objects, function(x) file.path(path, paste0(x, ext)))
  out <- unlink(files)
  ifelse(quiet, return(invisible(out)), return(out))
}
