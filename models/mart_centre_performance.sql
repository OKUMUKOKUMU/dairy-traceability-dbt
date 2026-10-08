-- Collection centre scorecard: volume, transit loss, QA rejects, cold chain
select
    i.centre_id,
    c.centre_name,
    c.county,
    count(*)                                         as tankers,
    round(sum(i.litres_received), 0)                 as litres_received,
    round(sum(i.transit_loss_l) / sum(i.litres_dispatched), 4) as transit_loss_pct,
    round(avg(case when i.qa_status = 'REJECTED' then 1 else 0 end), 4) as qa_reject_rate,
    round(avg(case when i.cold_chain_breach then 1 else 0 end), 4)      as cold_chain_breach_rate
from {{ ref('stg_factory_intake') }} i
join {{ ref('collection_centres') }} c using (centre_id)
group by 1, 2, 3
order by litres_received desc
