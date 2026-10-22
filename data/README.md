# Seoul Bike Sharing Demand: original data

This is a **candidate** dataset for the project; group agreement is pending.

## Source and licence

Seoul Bike Sharing Demand [Dataset]. (2020). UCI Machine Learning Repository.
https://doi.org/10.24432/C5F62R

- Landing page: https://archive.ics.uci.edu/dataset/560/seoul+bike+sharing+demand
- Download: https://archive.ics.uci.edu/static/public/560/seoul%2Bbike%2Bsharing%2Bdemand.zip
- Retrieved: 22 October 2026 (UK local date at download).
- Licence: CC BY 4.0, https://creativecommons.org/licenses/by/4.0/
- File: `SeoulBikeData.csv`, copied unchanged from the downloaded ZIP.
- SHA-256: `373339b71a8935d69e9af0abf26a70744632119862eeb3919efb389a7b749c60`.

The CSV has 8,760 rows and 14 columns. One row describes one system-wide hour,
covering 1 December 2017 to 30 November 2018. No missing entries or duplicate
date-hour keys were found. The file uses Latin-1 encoding and day/month/year
dates. Renaming and parsing happen in R, without overwriting the source CSV.

## Variables used in R

| Short name | Original column | Meaning / units |
| --- | --- | --- |
| date | Date | Calendar date, day/month/year |
| rented_bikes | Rented Bike Count | Bikes rented during the hour |
| hour | Hour | Hour of day, 0–23 |
| temperature_c | Temperature(°C) | Air temperature, degrees Celsius |
| humidity_pct | Humidity(%) | Relative humidity, percent |
| wind_speed_ms | Wind speed (m/s) | Wind speed, metres/second |
| visibility_10m | Visibility (10m) | Visibility in units of 10 metres |
| dew_point_c | Dew point temperature(°C) | Dew point, degrees Celsius |
| solar_radiation | Solar Radiation (MJ/m2) | Solar radiation, MJ per square metre |
| rainfall_mm | Rainfall(mm) | Rainfall, millimetres |
| snowfall_cm | Snowfall (cm) | Snowfall, centimetres |
| season | Seasons | Winter, Spring, Summer or Autumn |
| holiday | Holiday | Holiday or No Holiday |
| functioning_day | Functioning Day | Yes or No, as recorded |

There are 295 records marked `No` for operating status, all with zero rentals.
They remain in `bikes`. Comparisons of rentals while operating use
`bikes_active` (8,465 rows). A closure does not measure zero underlying demand.
