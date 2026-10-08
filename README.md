# Dairy Traceability — dbt project for milk-to-dispatch genealogy

A dbt + DuckDB model of the data layer behind the **Dairy Production ERP** I architected. The ERP gives end-to-end milk traceability from **collection centres → factory intake → processing → finished-goods dispatch** across cheese, yoghurt, ice cream and bakery lines. It replaced a set of disconnected spreadsheets with one system.

> **Data note:** the seed CSVs are **synthetic** and come from `generate_seeds.py`: 8 Kenyan collection centres, ~8.9k farmer deliveries and one month of production. No company data is included.

## Lineage

```
seeds                         staging                     marts
─────                         ───────                     ─────
milk_collections  ──► stg_milk_collections ─┐
factory_intake    ──► stg_factory_intake ───┼──► fct_lot_traceability   (recall / genealogy)
batch_inputs      ──► stg_batch_inputs ─────┤
production_batches──► stg_production_batches┼──► fct_batch_yield ──► mart_line_yield_summary
dispatches        ──► stg_dispatches ───────┘
collection_centres ───────────────────────────► mart_centre_performance
```

| Model | Answers |
|---|---|
| `fct_lot_traceability` | *Which centres, tankers and farmer-days fed the product we shipped to Mombasa DC on 12 Sept?* Used for recall and quality investigations. |
| `fct_batch_yield` | Actual vs standard yield (kg/L), waste and offcuts per batch |
| `mart_line_yield_summary` | Monthly yield and waste by product line for the factory dashboard |
| `mart_centre_performance` | Centre scorecard: volume, transit loss, QA reject rate, cold-chain breaches (>6 °C) |

**Data tests (28 pass):** uniqueness and not-null on every key, plus referential integrity from intake to batch to dispatch and accepted values for QA status.

## Sample output — `mart_line_yield_summary` (Sept 2026, synthetic)

| product_line | batches | litres_in | output_kg | yield_kg_per_l | waste_and_offcuts_kg |
|:--|--:|--:|--:|--:|--:|
| Bakery | 17 | 22,991 | 6,887 | 0.300 | 1,712 |
| Cheese | 29 | 99,354 | 9,843 | 0.099 | 7,367 |
| Ice Cream | 24 | 56,958 | 31,356 | 0.551 | 3,384 |
| Yoghurt | 28 | 95,448 | 89,152 | 0.934 | 4,083 |

## Run it

```bash
pip install -r requirements.txt
python generate_seeds.py           # optional: regenerate the synthetic seeds
dbt build --profiles-dir .         # loads seeds, builds models, runs tests into dairy.duckdb
```

Query the results:

```bash
python -c "import duckdb; print(duckdb.connect('dairy.duckdb').sql('select * from main_analytics.mart_centre_performance'))"
```

**Stack:** dbt · DuckDB · SQL · Python (prod: SQL Server, Dataform, Power BI)
