-- One row per tanker arriving at the factory, with QA outcome and transit loss
select
    intake_id,
    cast(intake_date as date)            as intake_date,
    centre_id,
    litres_dispatched,
    litres_received,
    litres_dispatched - litres_received  as transit_loss_l,
    upper(qa_status)                     as qa_status,
    temp_c,
    temp_c > 6.0                         as cold_chain_breach
from {{ ref('factory_intake') }}
