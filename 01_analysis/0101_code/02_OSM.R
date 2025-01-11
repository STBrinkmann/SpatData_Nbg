#'
#' # 0. Overview
#' In this script I download parks and water areas from OSM.
#'

library(osmdata)
library(sf)
library(dplyr)

# AOI
aoi <- st_read("01_analysis/0102_data/02_processed/01_Nbg_Bezirke.gpkg") %>%
  summarise() %>%
  st_transform(4326)


#'
#' # 1. OSM - Water mask
#'

# 1. Get bounding box
bb <- st_bbox(aoi)

# 2. Query OSM for water features
q_water <- opq(bbox = bb, timeout = 1000) %>%
  add_osm_feature(key = "natural", value = "water") %>%
  osmdata_sf()

# 3. Intersect the results with your AOI to keep only what's inside
water_poly <- st_intersection(q_water$osm_polygons, aoi)
water_multipoly <- st_intersection(q_water$osm_multipolygons, aoi)

# 4. Combine and reproject results back to EPSG:25832
water_sf <- rbind(
  water_poly %>% select(geometry),
  water_multipoly %>% select(geometry)
) %>%
  st_transform(25832)

# Save
write_sf(water_sf, "01_analysis/0102_data/02_processed/02_Nbg_Water.gpkg")


#'
#' # 2. OSM - Parks (>1 ha)
#'

# Add a buffer to the AOI
bb <- aoi %>%
  st_buffer(5000) %>%
  st_bbox()

# 1. Query OSM for parks
q_parks <- opq(bbox = bb, timeout = 1000) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf()

# 2. Intersect the results with your AOI to keep only what's inside
parks_poly <- st_intersection(q_parks$osm_polygons, aoi)
parks_multipoly <- st_intersection(q_parks$osm_multipolygons, aoi)

# 3. Combine results
parks_sf <- rbind(
  parks_poly %>% select(geometry),
  parks_multipoly %>% select(geometry)
)

# 4. Reproject to EPSG:25832 and filter for size > 1 ha (10,000 m²)
parks_sf <- parks_sf %>%
  st_transform(25832) %>%
  mutate(area = st_area(geometry)) %>%
  filter(area > units::set_units(1, "ha")) %>%
  select(geometry) %>%
  distinct()

# Save
write_sf(parks_sf, "01_analysis/0102_data/02_processed/02_Nbg_Parks.gpkg")


#'
#' # 3. OSM - Broader Greenspace
#'

# 1 Prepare bounding box (expand AOI by 5 km, for instance)
bb <- aoi %>%
  st_buffer(5000) %>%
  st_bbox()

# 2 Query OSM for relevant green features + accessibility
q_greenspace <- opq(bbox = bb, timeout = 1000) %>%
  # OR-logic for multiple key-value pairs
  add_osm_features(
    features = c(
      'leisure="park"',
      'leisure="recreation_ground"',
      'boundary="nature_reserve"',
      'landuse="forest"',
      'landuse="meadow"',
      'leisure="garden"',
      'leisure="playground"',
      'amenity="community_centre"'
    )
  ) %>%
  osmdata_sf()

# 3 Intersect results with AOI, combine polygons and multipolygons
greenspace_poly <- st_intersection(q_greenspace$osm_polygons, aoi)
greenspace_mpoly <- st_intersection(q_greenspace$osm_multipolygons, aoi)

greenspace_sf <- rbind(
  greenspace_poly  %>% select(access, geometry),
  greenspace_mpoly %>% select(access, geometry)
) %>%
  filter(!access %in% c("customers", "no", "permissive", "private")) %>%
  select(-access)

# 4 Reproject & filter by size (> 1 ha), then remove duplicates
greenspace_sf <- greenspace_sf %>%
  st_transform(25832) %>%
  mutate(area = st_area(geometry)) %>%
  filter(area > units::set_units(1, "ha")) %>%
  select(geometry) %>%
  distinct()

# Save
write_sf(greenspace_sf, "01_analysis/0102_data/02_processed/02_Nbg_Greenspace.gpkg")

