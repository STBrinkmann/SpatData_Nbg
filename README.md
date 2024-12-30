
<!-- README.md is generated from README.Rmd. Please edit that file -->

## Project Overview

This project focuses on providing spatial and socioeconomic data of
Nuremberg, Germany.

## Generated Datasets

The generated data is too large to be published at GitHub, therefore it
was uploaded to Zenodo:

The following datasets have been generated and are used throughout the
analysis:

1.  **Statistical Office Nürnberg**
    1.  **01_Nbg_Bezirke.gpkg**
        - Geopackage containing the boundaries of Nuremberg’s districts
          (Bezirke).
    2.  **01_Nbg_Stadtteile.gpkg**
        - Geopackage containing the boundaries of Nuremberg’s
          neighborhoods (Stadtteile).
    3.  **01_Nbg_SES.xlsx**
        - Excel file with socioeconomic status (SES) data for
          Nuremberg’s districts, including indicators from 2023 such as
          inhabitants, inhabitants by age classes, inhabitants by sex,
          number of foreign people, households, and households by size.
2.  **OSM**
    1.  **02_Nbg_Parks.gpkg**
        - Geopackage containing spatial data on parks (\>1ha) in
          Nuremberg.
    2.  **02_Nbg_Water.gpkg**
        - Geopackage containing spatial data on water bodies, such as
          rivers and lakes, in Nuremberg.
3.  **Remote Sensing**
    1.  **1m resolution**
        1.  **03_dsm_1m.tif**
            - GeoTIFF file representing the Digital Surface Model (DSM)
              of Nuremberg with a 1-meter resolution, capturing the
              elevations of natural and built features.
        2.  **03_dtm_1m.tif**
            - GeoTIFF file representing the Digital Terrain Model (DTM)
              of Nuremberg with a 1-meter resolution, depicting the bare
              earth surface without vegetation or buildings.
        3.  **03_ndvi_01_1m.tif**
            - GeoTIFF file representing a binary greenness
              classification with a 1-meter resolution, classifying the
              area in 1=green and 0=no green.
    2.  **10m resolution**
        1.  **03_ndvi_10m.tif**
            - GeoTIFF file representing the Normalized Difference
              Vegetation Index (NDVI) at a 10-meter resolution,
              providing a broader overview of vegetation patterns.
        2.  **03_lai_10m.tif**
            - GeoTIFF file containing the Leaf Area Index (LAI) data at
              a 10-meter resolution, indicating the amount of leaf
              material in Nuremberg’s vegetation.
        3.  **03_lulc_10m.tif**
            - GeoTIFF file representing a binary greenness
              classification at a 10-meter resolution, classifying the
              area in 1=green and 0=no green.

## Notes

- Coordinate Reference System (CRS): ETRS89 / UTM zone 32N (EPSG:25832)
- For detailed code and specific analyses, refer to the scripts in the
  `01_analysis/0101_code` directory of this repository.
