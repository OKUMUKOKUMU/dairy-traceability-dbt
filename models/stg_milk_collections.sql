-- One row per farmer delivery at a collection centre
select
    collection_id,
    cast(collection_date as date) as collection_date,
    centre_id,
    farmer_id,
    cast(litres as double)  as litres,
    cast(fat_pct as double) as fat_pct
from {{ ref('milk_collections') }}
where litres > 0
