select
    dispatch_id,
    batch_id,
    cast(dispatch_date as date) as dispatch_date,
    destination,
    qty_kg
from {{ ref('dispatches') }}
