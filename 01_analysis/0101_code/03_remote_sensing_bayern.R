#'
#' # 0. Overview
#'
#' This script downloads and prepares remote sensing data for the city of Nuremberg.
#' For that I bulk-download the data from the Bavarian government. The data includes
#' Digital Elevation Models (DEM), Digital Surface Models (DSM), Orthophotos (RGB and CIR),
#' and house footprints in LoD2. The data is then prepared and brought to a 1m resolution.
#'

library(dplyr)
library(xml2)
library(progress)
library(terra)
library(sf)


#'
#' # 1. Download data
#'

# For now only do Nürnberg
url_vec <- "09564000"


#'
#' ### 1.1.1 DSM (aka DOM)
#'

all_names <- c()

for(url in url_vec) {
  temp_file <- tempfile(fileext = ".meta4")
  download.file(glue::glue("https://geodaten.bayern.de/odd/a/dom20/meta/DOM/metalink/{url}.meta4"),
                destfile = temp_file, mode = "wb")

  # Load in using XML
  doc <- read_xml(temp_file)

  # Get all names
  tmp <- doc %>% xml_children() %>% xml_attr("name") %>% na.omit()
  all_names <- c(all_names, tmp)
}

# Remove NA and duplicates
all_names <- unique(all_names[!is.na(all_names)])

# Bulk download URL
bay_url <- "https://download1.bayernwolke.de/a/dom20/DOM/"

# Download all data but first create a folder
if(!dir.exists("01_analysis/0102_data/01_raw/dsm/")) dir.create("01_analysis/0102_data/01_raw/dsm/")

# Progress bar with ETA for the download
pb <- progress_bar$new(total = length(all_names),
                       format = "Downloading [:bar] :percent ETA: :eta (:elapsed elapsed)")
for(name in all_names) {
  pb$tick()
  if(file.exists(paste0("01_analysis/0102_data/01_raw/dsm/", name))) next
  download.file(paste0(bay_url, name),
                destfile = paste0("01_analysis/0102_data/01_raw/dsm/", name),
                mode = "wb", quiet = TRUE)
}


#'
#' ### 1.1.2 DEM
#'

all_names <- c()

for(url in url_vec) {
  temp_file <- tempfile(fileext = ".meta4")
  download.file(glue::glue("https://geodaten.bayern.de/odd/a/dgm/dgm1/meta/metalink/{url}.meta4"),
                destfile = temp_file, mode = "wb")

  # Load in using XML
  doc <- read_xml(temp_file)

  # Get all names
  tmp <- doc %>% xml_children() %>% xml_attr("name") %>% na.omit()
  all_names <- c(all_names, tmp)
}

# Remove NA and duplicates
all_names <- unique(all_names[!is.na(all_names)])

# Lidar URL
bay_url <- "https://download1.bayernwolke.de/a/dgm/dgm1/"

# Download all data to the D drive. Create a folder called "lidar_bay" first
if(!dir.exists("01_analysis/0102_data/01_raw/dem/")) dir.create("01_analysis/0102_data/01_raw/dem/")

# Progress bar with ETA for the download
pb <- progress_bar$new(total = length(all_names),
                       format = "Downloading [:bar] :percent ETA: :eta (:elapsed elapsed)")
for(name in all_names) {
  pb$tick()
  if(file.exists(paste0("01_analysis/0102_data/01_raw/dem/", name))) next
  download.file(paste0(bay_url, name),
                destfile = paste0("01_analysis/0102_data/01_raw/dem/", name),
                mode = "wb", quiet = TRUE)
}


#'
#' ### 1.1.3 Orthophotos - CIR
#'

#' The CIR data is currently hard to download in bulk. Also it seems that the quality
#' is somewhat bad. However, I had 40cm res. CIR data from the Bavarian government.
#' I will use this data for now.

# Copy the data from P to work dir
if(!dir.exists("01_analysis/0102_data/01_raw/ortho_cir/")) dir.create("01_analysis/0102_data/01_raw/ortho_cir/")
unzip("/mnt/p/R/Nuernberg.zip", exdir = "01_analysis/0102_data/01_raw/ortho_cir/")

# Only keep .tif files
cir_files <- list.files("01_analysis/0102_data/01_raw/ortho_cir/", full.names = TRUE)
file.remove(cir_files[tools::file_ext(cir_files) != "tif"])


#'
#' # 2. Prepare data
#'

dir.create("01_analysis/0102_data/02_processed/", recursive = TRUE, showWarnings = FALSE)
aoi_sf <- read_sf("01_analysis/0102_data/02_processed/01_Nbg_Bezirke.gpkg") %>%
  summarise()


#'
#' ## 2.1 DEM
#' This comes at 1m res.

# Combine the rasters into one
dtm_paths <- list.files("01_analysis/0102_data/01_raw/dem", pattern = ".tif", full.names = TRUE)
dtm_list <- lapply(dtm_paths, function(x) {
  r <- rast(x)
  names(r) <- "dtm"
  r
})
dtm_clean <- terra::mosaic(sprc(dtm_list), filename = "01_analysis/0102_data/01_raw/dtm_mosaic.tif")
dtm_clean <- crop(dtm_clean, aoi_sf, mask = FALSE) # TRUE cause a weird issue resulting in bad values (i.e. only 1!!)

# Save the DEM
terra::writeRaster(dtm_clean, "01_analysis/0102_data/02_processed/03_dtm_1m.tif")
file.remove("01_analysis/0102_data/01_raw/dtm_mosaic.tif")
unlink("01_analysis/0102_data/01_raw/dem", recursive = TRUE)


#'
#' ## 2.2 DSM
#'

# Combine the rasters into one
dsm_paths <- list.files("01_analysis/0102_data/01_raw/dsm", pattern = ".tif", full.names = TRUE)
dsm_list <- lapply(dsm_paths, function(x) {
  r <- rast(x)
  names(r) <- "dsm"
  r
})
dsm_clean <- terra::mosaic(sprc(dsm_list), filename = "01_analysis/0102_data/01_raw/dsm_mosaic.tif")
dsm_clean <- crop(dsm_clean, aoi_sf, mask = FALSE)

# Save the DSM
terra::writeRaster(dsm_clean, "01_analysis/0102_data/02_processed/dsm.tif")
file.remove("01_analysis/0102_data/01_raw/dsm_mosaic.tif")
unlink("01_analysis/0102_data/01_raw/dsm", recursive = TRUE)


#'
#' ## 2.3. Orthophotos - CIR
#'

# Combine all orthophotos into one
ortho_paths <- list.files("01_analysis/0102_data/01_raw/ortho_cir/", pattern = ".tif", full.names = TRUE)
ortho_list <- lapply(ortho_paths, function(x) {
  r <- rast(x)
  names(r) <- c("NIR", "red", "green")
  r
})
ortho <- terra::mosaic(sprc(ortho_list),
                       filename = "01_analysis/0102_data/01_raw/ortho_mosaic.tif",
                       wopt = list(gdal = c("BIGTIFF=YES",
                                            "NUM_THREADS = ALL_CPUS")))
ortho_clean <- crop(ortho, aoi_sf, mask = FALSE)

# Save the Raster
terra::writeRaster(ortho_clean, "01_analysis/0102_data/02_processed/ortho_cir.tif")
file.remove("01_analysis/0102_data/01_raw/ortho_mosaic.tif")
unlink("01_analysis/0102_data/01_raw/ortho_cir", recursive = TRUE)

# Also calculate the NDVI
ortho_clean <- terra::rast("01_analysis/0102_data/02_processed/ortho_cir.tif")
ndvi <- (ortho_clean[[1]] - ortho_clean[[2]]) / (ortho_clean[[1]] + ortho_clean[[2]])
terra::writeRaster(ndvi, "01_analysis/0102_data/02_processed/ndvi.tif")


#'
#' # 3. Bring to 1m resolution
#'

dem <- rast("01_analysis/0102_data/02_processed/03_dtm_1m.tif")
dsm <- rast("01_analysis/0102_data/02_processed/dsm.tif")
ndvi <- rast("01_analysis/0102_data/02_processed/ndvi.tif")

# Bring all to the resolution of dem (it is at 1m)
dsm_1m <- resample(dsm, dem, method = "bilinear", threads = TRUE)
ndvi_1m <- resample(ndvi, dem, method = "bilinear", threads = TRUE)

# For the binary greenspace raster I'll use a threshold of >0.1. I tested multiple
# thresholds and think 0.1 has the best results in capturing greenspace
ndvi_01_1m <- ndvi_1m > 0.1
ndvi_01_1m <- ndvi_01_1m * 1

# Save
terra::writeRaster(dsm_1m, "01_analysis/0102_data/02_processed/03_dsm_1m.tif")
terra::writeRaster(ndvi_01_1m, "01_analysis/0102_data/02_processed/03_ndvi_01_1m.tif")

# Remove the fine DSM and NDVI
unlink("01_analysis/0102_data/02_processed/dsm.tif")
unlink("01_analysis/0102_data/02_processed/ndvi.tif")
unlink("01_analysis/0102_data/02_processed/ortho_cir.tif")


#'
#' # 4. Raster data at 10m resolution
#'

# Load 1m raster for the binary greenspace raster
lulc_1m <- rast("../CGEI_Nuernberg/01_analysis/0101_data/01_prepped_data/ndvi_01_1m.tif")
names(lulc_1m) <- "LULC"

# Bring to 10m
lulc_10m <- aggregate(lulc_1m, fact = 10, fun = mean)
lulc_10m <- lulc_10m > 0.5
lulc_10m <- as.int(lulc_10m)

# Crop to AOI
lulc_10m <- lulc_10m %>%
  crop(aoi_sf) %>%
  mask(aoi_sf)

# Load the Sentinel2 derived NDVI and LAI that I prepared using Google Earth Engine
ndvi_10m <- rast("/mnt/p/R/Remote Sensing Data/Bavaria/Sentinel2/Nbg_S2_NDVI.tif")
lai_10m <- rast("/mnt/p/R/Remote Sensing Data/Bavaria/Sentinel2/Nbg_S2_LAI.tif")

crs(lulc_10m) == crs(ndvi_10m) # TRUE
crs(lulc_10m) == crs(lai_10m)  # TRUE

# Make sure that the extent is the same
ndvi_10m <- resample(ndvi_10m, lulc_10m, method = "bilinear")
lai_10m <- resample(lai_10m, lulc_10m, method = "bilinear")

# Crop to AOI
ndvi_10m <- ndvi_10m %>%
  crop(aoi_sf) %>%
  mask(aoi_sf)
lai_10m <- lai_10m %>%
  crop(aoi_sf) %>%
  mask(aoi_sf)

# The LAI had a processing error it seems. Remove the odd values
lai_vals <- values(lai_10m)
lai_quantiles <- quantile(lai_vals, c(0.01, 0.99), na.rm = TRUE)
lai_10m <- clamp(lai_10m, lai_quantiles[1], lai_quantiles[2])

# Save
terra::writeRaster(ndvi_10m, "01_analysis/0102_data/02_processed/03_ndvi_10m.tif")
terra::writeRaster(lai_10m,  "01_analysis/0102_data/02_processed/03_lai_10m.tif")
terra::writeRaster(lulc_10m, "01_analysis/0102_data/02_processed/03_lulc_10m.tif")
