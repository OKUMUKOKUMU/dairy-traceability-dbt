-- Batch-level yield conversion, waste and variance vs standard
with inputs as (
    select batch_id, sum(litres_used) as litres_in, count(*) as tankers
    from {{ ref('stg_batch_inputs') }}
    group by 1
)
select
    b.batch_id,
    b.production_date,
    b.product_line,
    i.tankers,
    i.litres_in,
    b.output_kg,
    round(b.output_kg / i.litres_in, 4)                         as actual_yield_kg_per_l,
    b.standard_yield_kg_per_l,
    round(b.output_kg / i.litres_in / b.standard_yield_kg_per_l - 1, 4) as yield_variance_pct,
    b.waste_kg,
    b.offcuts_kg,
    round(b.waste_kg / i.litres_in, 4)                          as waste_kg_per_l
from {{ ref('stg_production_batches') }} b
join inputs i using (batch_id)
