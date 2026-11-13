#!/usr/bin/env python3
"""Measure linkage quality with Splink 5 against known true entities.

    python splink/dedupe.py                  # fake_1000 (calibrated demo)
    python splink/dedupe.py --dataset zones  # the planted zone fixture (hard case)

The question is not "did Splink find matches" but "what are the precision and
recall, and where does the loss come from". Four measurements, in the order that
matters:

1. BLOCKING RECALL CEILING. Blocking rules decide which pairs are ever compared.
   A true pair the rules never generate is unreachable at any threshold. This is
   the number most linkage projects never measure and then blame on the model.
2. THRESHOLD TRADE-OFF. Precision and recall as the match-probability threshold
   moves. There is no single right threshold, only a cost of false merges and a
   cost of missed merges.
3. CLUSTER PURITY. Pairwise metrics can look fine while transitive clustering
   fuses two real entities into one. Purity catches that.
4. The tool's own evaluation, as a cross-check of the three numbers above.

Splink 5 API notes (why the code looks like this):
  * inputs are registered on the db_api; the Linker takes the registered frame
  * `block_on` takes separate arguments, not a list
  * `substr()` on a DATE column does not bind — block on `year(dob)`
  * comparisons used in an EM blocking rule are excluded from that pass, by design
  * `bf_` prefixes are now `mw_`; `match_probability` is unchanged
  * predictions/clusters live in the db_api's connection, so query that connection
    and reference `physical_name`; a separate duckdb.connect() cannot see them
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pyarrow.csv as pacsv

from splink import DuckDBAPI, Linker, SettingsCreator, block_on
import splink.comparison_library as cl

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"

DATASETS = {
    "fake": {
        "file": DATA / "fake_1000.csv",
        "id": "unique_id",
        "label": "cluster",
        "comparisons": [
            cl.JaroWinklerAtThresholds("first_name", [0.9, 0.7]),
            cl.JaroWinklerAtThresholds("surname", [0.9, 0.7]),
            cl.ExactMatch("dob"),
            cl.LevenshteinAtThresholds("city", [3, 1]),
            cl.JaroWinklerAtThresholds("email", [0.9, 0.7]),
        ],
        "blocking": [
            block_on("substr(surname,1,2)"),
            block_on("year(dob)"),
            block_on("substr(city,1,4)"),
        ],
        "em_rules": [
            block_on("substr(surname,1,2)"),
            block_on("substr(first_name,1,2)"),
            block_on("dob"),
        ],
        "prior_rule": block_on("substr(surname,1,2)", "year(dob)"),
        "prior_recall": 0.7,
        "train_from_labels": False,
    },
    "zones": {
        "file": DATA / "zones_dupes.csv",
        "id": "record_id",
        "label": "true_location_id",
        "comparisons": [
            cl.JaroWinklerAtThresholds("name", [0.95, 0.88, 0.80]),
            cl.ExactMatch("borough"),
        ],
        "blocking": [
            block_on("substr(name,1,4)"),
            block_on("substr(name,1,6)"),
            block_on("borough"),
        ],
        # EM cannot train `name` here without blocking on `name`, and blocking on
        # `name` excludes it from that pass. With ground truth available, estimate
        # m from the labels instead — an honest, supervised alternative.
        "em_rules": [],
        "prior_rule": block_on("substr(name,1,4)", "borough"),
        "prior_recall": 0.8,
        "train_from_labels": True,
    },
}


def section(title: str) -> None:
    print(f"\n{'=' * 72}\n{title}\n{'=' * 72}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", choices=sorted(DATASETS), default="fake")
    args = ap.parse_args()
    cfg = DATASETS[args.dataset]

    if not cfg["file"].exists():
        sys.exit(f"missing {cfg['file']} — for zones run `python splink/plant_dupes.py` first")

    table = pacsv.read_csv(cfg["file"])
    db_api = DuckDBAPI()
    records = db_api.register(table, dataset_display_name="records")
    con = db_api.duckdb_con

    settings = SettingsCreator(
        link_type="dedupe_only",
        unique_id_column_name=cfg["id"],
        comparisons=cfg["comparisons"],
        blocking_rules_to_generate_predictions=cfg["blocking"],
        retain_matching_columns=True,
    )
    linker = Linker(records, settings)

    linker.training.estimate_u_using_random_sampling(max_pairs=2e6)
    if cfg["train_from_labels"]:
        linker.training.estimate_m_from_label_column(cfg["label"])
    else:
        for rule in cfg["em_rules"]:
            linker.training.estimate_parameters_using_expectation_maximisation(rule)
    linker.training.estimate_probability_two_random_records_match(
        [cfg["prior_rule"]], recall=cfg["prior_recall"]
    )

    predictions = linker.inference.predict(threshold_match_probability=0.2)
    pred = predictions.physical_name
    id_l, id_r = f"{cfg['id']}_l", f"{cfg['id']}_r"

    true_pairs = con.execute(
        f"select sum(n * (n - 1) / 2) from (select {cfg['label']}, count(*) n "
        f"from records group by 1)"
    ).fetchall()[0][0]

    def score(threshold: float) -> tuple[int, int]:
        return con.execute(f"""
            select
                count(*) filter (where a.{cfg['label']} = b.{cfg['label']}) as tp,
                count(*) filter (where a.{cfg['label']} <> b.{cfg['label']}) as fp
            from {pred} p
            join records a on a.{cfg['id']} = p.{id_l}
            join records b on b.{cfg['id']} = p.{id_r}
            where p.match_probability >= ?
        """, [threshold]).fetchall()[0]

    section(f"1. Blocking recall ceiling — dataset: {args.dataset}")
    reachable, _ = score(0.0)
    print(f"true pairs in the data       : {true_pairs:.0f}")
    print(f"pairs the blocking rules saw : {reachable}")
    print(f"blocking recall ceiling      : {reachable / true_pairs:.3f}")
    print("Every true pair the rules never generate is lost before the model runs.")

    section("2. Precision / recall by threshold")
    print(f"{'threshold':>10} {'tp':>6} {'fp':>6} {'fn':>7} {'precision':>10} {'recall':>8} {'f1':>7}")
    for threshold in (0.50, 0.70, 0.85, 0.95, 0.99):
        tp, fp = score(threshold)
        fn = true_pairs - tp
        precision = tp / (tp + fp) if tp + fp else float("nan")
        recall = tp / true_pairs
        f1 = 2 * precision * recall / (precision + recall) if precision + recall else float("nan")
        print(f"{threshold:>10.2f} {tp:>6} {fp:>6} {fn:>7.0f} {precision:>10.3f} {recall:>8.3f} {f1:>7.3f}")

    section("3. Cluster purity at threshold 0.85")
    clusters = linker.clustering.cluster_pairwise_predictions_at_threshold(
        predictions, threshold_match_probability=0.85
    )
    n_clusters, n_entities, mixed, rec_pure, rec_total = con.execute(f"""
        with joined as (
            select c.cluster_id, r.{cfg['label']} as entity
            from {clusters.physical_name} c
            join records r on r.{cfg['id']} = c.{cfg['id']}
        ),
        per_cluster as (
            select cluster_id, count(*) n_records, count(distinct entity) n_entities
            from joined group by 1
        )
        select count(*),
               (select count(distinct {cfg['label']}) from records),
               count(*) filter (where n_entities > 1),
               sum(n_records) filter (where n_entities = 1),
               sum(n_records)
        from per_cluster
    """).fetchall()[0]
    print(f"clusters produced            : {n_clusters}")
    print(f"true entities                : {n_entities}")
    print(f"clusters mixing entities     : {mixed}")
    print(f"records in pure clusters     : {rec_pure}/{rec_total} = {rec_pure / rec_total:.3f}")

    section("4. Splink's own evaluation table (cross-check, different denominator)")
    # Note the denominator: this table scores every one of the N*(N-1)/2 pairs,
    # so pairs the blocking rules never generated are counted as misses. Our
    # section 2 uses the same convention for recall but reports precision only
    # over pairs actually compared, which is why the two precision columns
    # differ. Two honest numbers, two different questions.
    eval_table = linker.evaluation.accuracy_analysis_from_labels_column(
        cfg["label"], output_type="table", threshold_match_probability=0.85
    )
    print(f"{'match_probability':>18} {'tp':>6} {'fp':>7} {'fn':>5} {'precision':>10} {'recall':>8}")
    rows = eval_table.as_record_list()
    for target in (0.5, 0.85, 0.99):
        row = min(rows, key=lambda r: abs(r["match_probability"] - target))
        print(
            f"{row['match_probability']:>18.4f} {int(row['tp']):>6} {int(row['fp']):>7} "
            f"{int(row['fn']):>5} {row['precision']:>10.3f} {row['recall']:>8.3f}"
        )


if __name__ == "__main__":
    main()
