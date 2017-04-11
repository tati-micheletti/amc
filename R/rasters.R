#' Crop and reproject a raster to a given study area
#'
#' This function is geared toward use with study areas that are too large to work
#' with in memory, as it always writes temporary intermediate files to disk.
#' All temporary intermediate files are removed on exit to prevent "disk-full" errors,
#' as normally, the system temp directory is only emptied on reboot.
#'
#' @note Currently, only works with a \code{RasterStack} object from file, and
#' is only tested using \code{studyArea} as a  \code{SpatialPolygonsDataFrame}.
#'
#' @param x          \code{RasterStack} object or the filepath to such object.
#'
#' @param studyArea  A \code{SpatialPolygonsDataFrame} object.
#'
#' @param layerNames A character vector of layer names to assign the raster.
#'
#' @param filename   Optional output filepath to use with \code{\link{writeRaster}}.
#'                   If not specified, a temporary file will be used.
#'
#' @param ...        Additional arguments (not used).
#'
#' @author Alex Chubaty and Eliot Mcintire
#' @docType methods
#' @export
#' @importFrom magrittr '%>%' set_names
#' @importFrom raster crop projectRaster stack writeRaster
#' @importFrom sp CRS proj4string spTransform
#' @rdname cropReproj
#'
setGeneric("cropReproj",
           function(x, studyArea, ...) {
             standardGeneric("cropReproj")
})

#' @export
#' @rdname cropReproj
setMethod(
  "cropReproj",
  signature("RasterStack", "SpatialPolygonsDataFrame"),
  definition = function(x, studyArea, layerNames, filename = NULL, ...) {
    stopifnot(nlayers(x) == length(layerNames))

    tempfiles <- lapply(rep(".tif", 3), tf)
    on.exit(lapply(tf, unlink))

    ## TO DO: can this part be made parallel?
    a <- set_names(x, layerNames)
    b <- spTransform(studyArea, CRSobj = CRS(proj4string(a)))
    a <- crop(a, b, filename = tempfiles[[1]], overwrite = TRUE) %>%
      projectRaster(., crs = CRS(proj4string(studyArea)), method = "ngb",
                    filename = tempfiles[[2]], overwrite = TRUE) %>%
      crop(studyArea, filename = tempfiles[[3]], overwrite = TRUE) %>%
      set_names(layerNames)

    if (is.null(filename)) {
      a <- writeRaster(a, filename = tf(".tif"), overwrite = TRUE)
    } else {
      a <- writeRaster(a, filename = filename, overwrite = TRUE)
    }
    return(a)
})

#' @export
#' @rdname cropReproj
setMethod(
  "cropReproj",
  signature("character", "SpatialPolygonsDataFrame"),
  definition = function(x, studyArea, layerNames, filename = NULL, ...) {
    stopifnot(file.exists(x))
    x <- stack(x = x)
    cropReproj(x, studyArea, layerNames, filename, ...)
})

#' Merge Raster* objects using a function for overlapping areas
#'
#' Provides a wrapper around \code{\link[raster]{mosaic}} that cleans up any
#' temporary intermediate files used, and sets the layer name of the resulting raster.
#'
#' @param x   \code{Raster*} object
#' @param y   \code{Raster*} object
#' @param ... Additional Raster or Extent objects.
#' @param fun Function (e.g., \code{mean}, \code{min}, or \code{max}, that accepts
#'            a \code{na.rm} argument).
#' @param tolerance Numeric. Permissible difference in origin (relative to the
#'                  cell resolution). See \code{\link{all.equal}}.
#' @param filename  Character. Output filename (optional).
#' @param layerName Character. Name of the resulting raster layer.
#'
#' @author Alex Chubaty
#' @docType methods
#' @export
#' @importFrom magrittr '%>%' set_names
#' @importFrom raster mosaic writeRaster
#' @rdname mosaic2
setGeneric("mosaic2",
           function(x, y, ...) {
  standardGeneric("mosaic2")
})

#' @export
#' @rdname mosaic2
setMethod("mosaic2",
          signature("RasterLayer", "RasterLayer"),
          definition = function(x, y, ..., fun, tolerance = 0.05, filename = NULL,
                                layerName = "layer") {
  tempfiles <- list(tf(".tif"))

  ## TO DO: can this part be made parallel?
  out <- mosaic(x, y, ..., fun = fun, tolerance = tolerance, filename = tempfiles[[1]]) %>%
    writeRaster(filename = filename, overwrite = TRUE) %>%
    set_names(layerName)
  return(out)
})