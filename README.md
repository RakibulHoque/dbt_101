# A Sample DBT project with testing

## Requirements
- You must have [python](https://www.python.org/downloads/) installed (version >= 3.8)
- You must have [gcloud cli](https://cloud.google.com/sdk/docs/install) tool installed
- You must have access to specific gcloud projects
## Setup
```
gcloud auth login --update-adc
source init.sh
cd $DBT_PROJECT_DIR && dbt debug
```

## Refs
https://www.astrafy.io/articles/dbt-at-scale-on-google-cloud-part-1
