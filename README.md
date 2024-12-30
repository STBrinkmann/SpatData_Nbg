
<!-- README.md is generated from README.Rmd. Please edit that file -->

## Project Overview

This project provides spatial and socioeconomic data for Nuremberg,
Germany. Due to size constraints, all data has been uploaded to Zenodo.

## Generated Datasets

1.  **Statistical Office Nürnberg**
    1.  **01_Nbg_Bezirke.gpkg**
        - Geopackage containing the boundaries of Nuremberg’s districts
          (Bezirke).
    2.  **01_Nbg_Stadtteile.gpkg**
        - Geopackage containing the boundaries of Nuremberg’s
          neighborhoods (Stadtteile).
    3.  **01_Nbg_SES.xlsx**
        - Excel file with socioeconomic status (SES) data for
          Nuremberg’s districts, including 2023 indicators such as
          inhabitants, age distribution, gender, number of foreign
          residents, households, and household sizes.
2.  **OSM**
    1.  **02_Nbg_Parks.gpkg**
        - Geopackage containing spatial data on parks larger than 1
          hectare in Nuremberg.
    2.  **02_Nbg_Water.gpkg**
        - Geopackage containing spatial data on water bodies, such as
          rivers and lakes, in Nuremberg.
3.  **Remote Sensing**
    1.  **1m resolution**
        1.  **03_dsm_1m.tif**
            - GeoTIFF representing the Digital Surface Model (DSM) of
              Nuremberg at 1-meter resolution, capturing elevations of
              natural and built features.
        2.  **03_dtm_1m.tif**
            - GeoTIFF representing the Digital Terrain Model (DTM) of
              Nuremberg at 1-meter resolution, depicting the bare earth
              surface without vegetation or buildings.
        3.  **03_ndvi_01_1m.tif**
            - GeoTIFF representing a binary greenness classification at
              1-meter resolution, with 1 indicating green areas and 0
              indicating non-green areas.
    2.  **10m resolution**
        1.  **03_ndvi_10m.tif**
            - GeoTIFF representing the Normalized Difference Vegetation
              Index (NDVI) at 10-meter resolution, providing an overview
              of vegetation patterns.
        2.  **03_lai_10m.tif**
            - GeoTIFF containing the Leaf Area Index (LAI) data at
              10-meter resolution, indicating the amount of leaf
              material in Nuremberg’s vegetation.
        3.  **03_lulc_10m.tif**
            - GeoTIFF representing a binary greenness classification at
              10-meter resolution, with 1 indicating green areas and 0
              indicating non-green areas.

## Notes

- **Coordinate Reference System (CRS)**: All datasets use ETRS89 / UTM
  zone 32N (EPSG:25832).

For detailed code and specific analyses, refer to the scripts in the
`01_analysis/0101_code` directory of this repository.
