{{ config(materialized='table') }}

SELECT
    JSONExtractFloat(`_airbyte_data`, 'sepal.length') AS sepal_length
    , JSONExtractFloat(`_airbyte_data`, 'sepal.width') AS sepal_width
    , JSONExtractFloat(`_airbyte_data`, 'petal.length') AS petal_length
    , JSONExtractFloat(`_airbyte_data`, 'petal.width') AS petal_width
    , JSONExtractFloat(`_airbyte_data`, 'variety') AS variety
    , JSONExtractRaw(`_airbyte_data`, '_ab_additional_properties') AS _ab_additional_properties
    , JSONExtractRaw(`_airbyte_data`, '_ab_source_file_last_modified') AS _ab_source_file_last_modified
    , JSONExtractRaw(`_airbyte_data`, '_ab_source_file_url') AS _ab_source_file_url
    , `_airbyte_ab_id`
    , `_airbyte_emitted_at`

FROM
    {{ source("foo_source", "_airbyte_raw_iris_data")}}