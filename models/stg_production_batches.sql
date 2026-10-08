select
    batch_id,
    cast(production_date as date) as production_date,
    product_line,
    standard_yield_kg_per_l,
    output_kg,
    waste_kg,
    offcuts_kg
from {{ ref('production_batches') }}
