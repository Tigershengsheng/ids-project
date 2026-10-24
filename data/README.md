# Data provenance

Acquired on 24 October 2026.

- `uci_cdc_diabetes_891.csv`: direct UCI dataset 891 CSV, 253,680 rows,
  21 predictors, outcome and a row ID.
  Source: https://archive.ics.uci.edu/static/public/891/data.csv
- `diabetes_012_health_indicators_BRFSS2015.csv`: original three-category
  file from the dataset homepage linked by UCI, used to audit outcome labels.
  Source: https://www.kaggle.com/datasets/alexteboul/diabetes-health-indicators-dataset
- `original_kaggle_archive.zip`: locally retained original download,
  containing all three published versions. Excluded from Git to avoid
  redundant copies; the two required CSVs above are included.
- `uci_metadata_891.json`, `kaggle_metadata.json`: original metadata snapshots.
- `label_mapping_audit.json`: direct comparison of all rows and predictors.
- `access_check.json`, `original_versions_audit.json`: acquisition checks.

The Kaggle publisher declares CC0 (Public Domain), recorded in
`kaggle_metadata.json`. CDC asks users to acknowledge BRFSS as the original
source. See the citations in the report.

The source is the cleaned **2015 BRFSS** dataset. Some fields on the UCI
webpage refer to 2014 or 2017 and its abstract mentions 35 variables; those
fields do not describe the actual CSV consistently. The actual supplied
file has 21 indicators. The original publisher's description identifies
the survey as 2015, and its original feature rows match UCI exactly.

## Outcome definition

| Original three-category code | Original meaning | UCI binary code | N |
|---|---|---:|---:|
| 0 | No diabetes / diabetes only during pregnancy | 0 | 213,703 |
| 1 | Prediabetes | 0 | 4,631 |
| 2 | Diabetes | 1 | 35,346 |

The statement in the webpage descriptions that binary 1 includes
prediabetes disagrees with the actual file mapping. The analysis follows
the verified file mapping and reports the disagreement explicitly.

No survey weights, strata or sampling-cluster variables are present in
the cleaned extract. Do not report its unweighted percentages as national
prevalence. Do not delete repeated response profiles automatically:
different people may give the same categorical survey answers.

The raw CSVs are unchanged. Factor labels, the split and modelling are
created in R. SHA-256 hashes are stored in `results/analysis.json`.
