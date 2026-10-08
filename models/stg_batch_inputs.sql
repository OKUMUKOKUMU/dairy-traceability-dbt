-- Bridge: which factory intakes (tankers) went into which production batch
select batch_id, intake_id, litres_used from {{ ref('batch_inputs') }}
