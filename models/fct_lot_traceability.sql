-- Full genealogy: every dispatch traced back to batch, tanker, collection centre
-- and the farmers who supplied that centre on that day.
-- Answers recall questions like "which farmers and centres fed what went to Mombasa DC on 12 Sept?"
with farmers as (
    select centre_id, collection_date,
           count(distinct farmer_id) as farmers,
           sum(litres)               as litres_collected,
           round(avg(fat_pct), 2)    as avg_fat_pct
    from {{ ref('stg_milk_collections') }}
    group by 1, 2
)
select
    d.dispatch_id,
    d.dispatch_date,
    d.destination,
    d.qty_kg,
    b.batch_id,
    b.product_line,
    b.production_date,
    bi.intake_id,
    bi.litres_used,
    fi.centre_id,
    cc.centre_name,
    cc.county,
    fi.qa_status,
    fi.cold_chain_breach,
    f.farmers,
    f.litres_collected,
    f.avg_fat_pct
from {{ ref('stg_dispatches') }} d
join {{ ref('stg_production_batches') }} b  using (batch_id)
join {{ ref('stg_batch_inputs') }}      bi using (batch_id)
join {{ ref('stg_factory_intake') }}    fi using (intake_id)
join {{ ref('collection_centres') }}    cc on cc.centre_id = fi.centre_id
left join farmers f on f.centre_id = fi.centre_id and f.collection_date = fi.intake_date
