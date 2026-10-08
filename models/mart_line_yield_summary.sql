-- Monthly product-line yield and waste summary for the factory dashboard
select
    product_line,
    date_trunc('month', production_date)    as month,
    count(*)                                as batches,
    round(sum(litres_in), 0)                as litres_in,
    round(sum(output_kg), 0)                as output_kg,
    round(sum(output_kg) / sum(litres_in), 4) as yield_kg_per_l,
    round(avg(yield_variance_pct), 4)       as avg_yield_variance_pct,
    round(sum(waste_kg) + sum(offcuts_kg), 0) as waste_and_offcuts_kg
from {{ ref('fct_batch_yield') }}
group by 1, 2
order by 1, 2
