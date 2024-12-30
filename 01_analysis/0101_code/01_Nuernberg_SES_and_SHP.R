#'
#' # 0. Overview
#'
#' This script first loads the shapefiles ("Stadtteile" and "Bezirke") for the city
#' of Nuremberg, and then prepares the socio-economic (SES) data for the city.
#' The shapefiles can be found on OSM-Wiki. The SES data is from the statistical
#' office of the city of Nuremberg, but it only comes as PDFs.
#'

library(sf)
library(dplyr)
library(tabulapdf)


#'
#' # 1. Load the shapefiles
#'
#' https://wiki.openstreetmap.org/wiki/N%C3%BCrnberg/Stadtteile#Quellen
#'

# Bezirke
# https://cloud.friedrich.rocks/s/8g2kPtrglFWldqs/download/Geometrie_NUE_Bezirke.zip
download.file("https://cloud.friedrich.rocks/s/8g2kPtrglFWldqs/download/Geometrie_NUE_Bezirke.zip",
              destfile = "01_analysis/0102_data/01_raw/Geometrie_NUE_Bezirke.zip")
unzip(zipfile = "01_analysis/0102_data/01_raw/Geometrie_NUE_Bezirke.zip",
      exdir = "01_analysis/0102_data/01_raw/Geometrie_NUE_Bezirke")
unlink("01_analysis/0102_data/01_raw/Geometrie_NUE_Bezirke.zip")

# Stadtteile
# https://cloud.friedrich.rocks/s/AMaUtqwAy3gln0M/download/Geometrie_NUE_Stadtteile.zip
download.file("https://cloud.friedrich.rocks/s/AMaUtqwAy3gln0M/download/Geometrie_NUE_Stadtteile.zip",
              destfile = "01_analysis/0102_data/01_raw/Geometrie_NUE_Stadtteile.zip")
unzip(zipfile = "01_analysis/0102_data/01_raw/Geometrie_NUE_Stadtteile.zip",
      exdir = "01_analysis/0102_data/01_raw/Geometrie_NUE_Stadtteile")
unlink("01_analysis/0102_data/01_raw/Geometrie_NUE_Stadtteile.zip")

# Prepare the shapefiles
sf_bez <- read_sf("01_analysis/0102_data/01_raw/Geometrie_NUE_Bezirke") %>%
  st_transform(25832) %>%
  select(code_bez = 2, name_bez = 3) %>%
  mutate(code_stadtteil = substr(code_bez, 1, 1)) %>%
  relocate(code_stadtteil)

sf_stadtteil <- read_sf("01_analysis/0102_data/01_raw/Geometrie_NUE_Stadtteile") %>%
  st_transform(25832) %>%
  select(code_stadtteil = 1, name_stadtteil = 2)

# Save
write_sf(sf_bez, "01_analysis/0102_data/02_processed/01_Nbg_Bezirke.gpkg")
write_sf(sf_stadtteil, "01_analysis/0102_data/02_processed/01_Nbg_Stadtteile.gpkg")

unlink("01_analysis/0102_data/01_raw/Geometrie_NUE_Bezirke", recursive = TRUE)
unlink("01_analysis/0102_data/01_raw/Geometrie_NUE_Stadtteile", recursive = TRUE)

#'
#' # 2. SES data
#'

# Auszug Innergebietliche Strukturdaten Nürnberg 2023
# https://www.nuernberg.de/internet/statistik/gebietszahlen.html
url_pdf <- "https://www.nuernberg.de/imperia/md/statistik/dokumente/veroeffentlichungen/tabellenwerke/gebietszahlen/innergebietliche_strukturdaten_nuernberg_2023_www-version_geschwarzt.pdf"

#' ## 2.1 Einwohner & Ausländer
#' wohnberechtigte:       Wohnberechtigte Bevölkerung
#' einwohner:             Bevölkerung mit Hauptwohnung
#' einwohner_auslaender:  Personen ohne deutsche Staatsangehörigkeit
#' einwohner_migration:   Ausländer und Deutsche mit familiärem Migrationshinter
#'                        -grundnach Ableitung mit MigraPro.

data <- extract_areas(url_pdf, col_names = FALSE, pages = c(15, 17), resolution = 100)

ses_einwohner <- lapply(data, function(x) {
  x %>%
    select(
      code_bez = 1,
      wohnberechtigte = 3,
      einwohner = 5,
      einwohner_auslaender = 6,
      einwohner_migration = 8
    ) %>%
    mutate(code_bez = as.character(code_bez)) %>%
    mutate(across(-code_bez, ~ as.numeric(gsub(" ", "", .))))
}) %>%
  bind_rows()

#' ## 2.2 Altersklassen
#' einwohner:             Bevölkerung mit Hauptwohnung
#' age_classes:           Einwohner im Alter von ... bis unter ... Jahren
#' age_mittel:            Durchschnittsalter
data <- extract_areas(url_pdf, col_names = FALSE, pages = c(25, 27), resolution = 100)

ses_alter <- lapply(data, function(x) {
  x %>%
    select(
      code_bez = 1,
      einwohner = 2,
      age_00_03 = 3,
      age_03_06 = 4,
      age_06_15 = 5,
      age_15_18 = 6,
      age_18_25 = 7,
      age_25_45 = 8,
      age_45_65 = 9,
      age_65_80 = 10,
      age_80_pp = 11,
      age_mittel = 12
    ) %>%
    mutate(code_bez = as.character(code_bez)) %>%
    mutate(across(-code_bez, ~ as.numeric(gsub(" ", "", .)))) %>%
    mutate(age_mittel = age_mittel / 10)
}) %>%
  bind_rows()

# Check
anti_join(ses_einwohner, ses_alter, by = join_by(code_bez, einwohner)) # 0
anti_join(ses_alter, ses_einwohner, by = join_by(code_bez, einwohner)) # 0

#' ## 2.3 Geschlecht
#' Geschlecht:              Zahl der Personen mit dem jeweiligen Geschlecht. Diverse
#'                          Menschen und Personen ohne Angaben zum Geschlecht im
#'                          Melderegister (vgl. § 22 Abs. 3 Personenstandsgesetz)
#'                          werden zur statistischen Auswertbarkeit anhand ihres
#'                          Geburtstages (ungerade=männlich, gerade=weiblich)
#'                          den binären Geschlechtsausprägungen zugeordnet.
data <- extract_areas(url_pdf, col_names = FALSE, pages = c(26, 28), resolution = 100)

ses_gender <- lapply(data, function(x) {
  x %>%
    select(code_bez = last_col(), gen_male = 1, gen_fem = 2) %>%
    mutate(code_bez = as.character(code_bez)) %>%
    mutate(across(-code_bez, ~ as.numeric(gsub(" ", "", .))))
}) %>%
  bind_rows()

# Check
anti_join(ses_einwohner, ses_gender, by = join_by(code_bez)) # 0
anti_join(ses_gender, ses_einwohner, by = join_by(code_bez)) # 0

#' ## 2.4 Haushalte
data <- extract_areas(url_pdf, col_names = FALSE, pages = c(33, 34), resolution = 100)

ses_hh <- lapply(data, function(x) {
  x %>%
    select(
      code_bez = 1,
      haushalte = 2,
      hhsize_1 = 3,
      hhsize_2 = 4,
      hhsize_3 = 5,
      hhsize_4 = 6,
      hhsize_5p = 7,
      hhsize_mittel = 8
    ) %>%
    mutate(code_bez = as.character(code_bez)) %>%
    mutate(across(-code_bez, ~ as.numeric(gsub(" ", "", .)))) %>%
    mutate(hhsize_mittel = hhsize_mittel / 10)
}) %>%
  bind_rows()

# There was one issue when pasing the PDF
ses_hh$hhsize_mittel[ses_hh$code_bez == "34"] <- 1.0

# Check
anti_join(ses_einwohner, ses_hh, by = join_by(code_bez)) # 0
anti_join(ses_hh, ses_einwohner, by = join_by(code_bez)) # 0

# ## 2.5 Combine
ses_nbg <- ses_einwohner %>%
  left_join(ses_alter, by = join_by(code_bez, einwohner)) %>%
  left_join(ses_gender, by = join_by(code_bez)) %>%
  left_join(ses_hh, by = join_by(code_bez))

# Check if the mean hh size is correct
ses_nbg %>%
  select(code_bez, einwohner, haushalte, hhsize_mittel) %>%
  mutate(hhsize_calc = round(einwohner / haushalte, 1)) %>%
  filter(hhsize_mittel != hhsize_calc)

# Bez. "34" (Beuthener Straße) looks very odd
ses_nbg %>% filter(code_bez == "34") %>% glimpse()
sf_bez %>% filter(code_bez == "34") %>% mapview::mapview()

#' ## 2.6 Quality Controll and save
ses_nbg %>% filter(wohnberechtigte < einwohner) # 0

ses_nbg %>%
  select(code_bez, einwohner, starts_with("age"), -age_mittel) %>%
  mutate(tst = rowSums(across(starts_with("age")))) %>%
  filter(einwohner != tst) # 0

ses_nbg %>%
  select(code_bez, einwohner, starts_with("gen")) %>%
  mutate(tst = rowSums(across(starts_with("gen")))) %>%
  filter(einwohner != tst) # 0

ses_nbg %>%
  select(code_bez, haushalte, starts_with("hhsize"), -hhsize_mittel) %>%
  mutate(tst = rowSums(across(starts_with("hhsize")))) %>%
  filter(haushalte != tst) # 0

writexl::write_xlsx(ses_nbg, "01_analysis/0102_data/02_processed/01_Nbg_SES.xlsx")
