"""Generate synthetic seed CSVs for the dairy traceability dbt project.

Milk flows: farmer -> collection centre -> factory intake (QA) -> production batch
-> finished goods dispatch. No real data is included.
Usage: python generate_seeds.py
"""
from pathlib import Path

import numpy as np
import pandas as pd

RNG = np.random.default_rng(11)
SEEDS = Path(__file__).parent / "seeds"
SEEDS.mkdir(exist_ok=True)

centres = pd.DataFrame({
    "centre_id": [f"CC{i:02d}" for i in range(1, 9)],
    "centre_name": ["Ol Kalou", "Kinangop", "Molo", "Kipkelion", "Nyahururu", "Limuru", "Githunguri", "Iten"],
    "county": ["Nyandarua", "Nyandarua", "Nakuru", "Kericho", "Laikipia", "Kiambu", "Kiambu", "Elgeyo-Marakwet"],
})

days = pd.date_range("2026-09-01", "2026-09-30")
collections, intakes = [], []
for d in days:
    for c in centres.centre_id:
        n_farmers = RNG.integers(25, 50)
        litres = RNG.gamma(4, 8, n_farmers).round(1)
        for f, l in enumerate(litres):
            collections.append(dict(collection_id=f"COL-{d:%m%d}-{c}-{f:03d}", collection_date=d.date(),
                                    centre_id=c, farmer_id=f"F{c[2:]}{f:03d}", litres=l,
                                    fat_pct=round(RNG.normal(3.8, .3), 2)))
        # one tanker per centre per day delivers the pooled milk to the factory
        total = litres.sum()
        intakes.append(dict(intake_id=f"INT-{d:%m%d}-{c}", intake_date=d.date(), centre_id=c,
                            litres_dispatched=round(total, 1),
                            litres_received=round(total * RNG.uniform(.985, 1.0), 1),
                            qa_status="REJECTED" if RNG.random() < .03 else "ACCEPTED",
                            temp_c=round(RNG.normal(4.5, 1.2), 1)))
collections, intakes = pd.DataFrame(collections), pd.DataFrame(intakes)

# Production: each day accepted intakes are allocated to product-line batches
LINES = {"Cheese": (0.10, .06), "Yoghurt": (0.95, .03), "Ice Cream": (0.55, .04), "Bakery": (0.30, .05)}
batches, inputs = [], []
for d in days:
    pool = intakes[(intakes.intake_date == d.date()) & (intakes.qa_status == "ACCEPTED")]
    for row in pool.itertuples():
        line = RNG.choice(list(LINES), p=[.4, .35, .15, .1])
        batch_id = f"PB-{d:%m%d}-{line[:3].upper()}"
        inputs.append(dict(batch_id=batch_id, intake_id=row.intake_id, litres_used=row.litres_received))
    for line, (std_yield, waste_rate) in LINES.items():
        batch_id = f"PB-{d:%m%d}-{line[:3].upper()}"
        litres_in = sum(i["litres_used"] for i in inputs if i["batch_id"] == batch_id)
        if litres_in == 0:
            continue
        actual = std_yield * RNG.normal(1, .04)
        waste = litres_in * waste_rate * RNG.uniform(.6, 1.5)
        batches.append(dict(batch_id=batch_id, production_date=d.date(), product_line=line,
                            standard_yield_kg_per_l=std_yield, output_kg=round(litres_in * actual, 1),
                            waste_kg=round(waste, 1), offcuts_kg=round(waste * RNG.uniform(.1, .4), 1)))
batches, inputs = pd.DataFrame(batches), pd.DataFrame(inputs)

dispatches = []
for b in batches.itertuples():
    remaining = b.output_kg
    for k in range(RNG.integers(1, 4)):
        qty = round(remaining * (RNG.uniform(.3, .6) if k < 2 else 1), 1)
        remaining -= qty
        dispatches.append(dict(dispatch_id=f"DSP-{b.batch_id[3:]}-{k}", batch_id=b.batch_id,
                               dispatch_date=(pd.Timestamp(b.production_date) + pd.Timedelta(days=int(RNG.integers(1, 4)))).date(),
                               destination=RNG.choice(["Nairobi DC", "Mombasa DC", "Kisumu DC", "Eldoret DC"]), qty_kg=qty))
dispatches = pd.DataFrame(dispatches)

for name, df in dict(collection_centres=centres, milk_collections=collections, factory_intake=intakes,
                     production_batches=batches, batch_inputs=inputs, dispatches=dispatches).items():
    df.to_csv(SEEDS / f"{name}.csv", index=False)
    print(f"seeds/{name}.csv  {len(df):>6,} rows")
