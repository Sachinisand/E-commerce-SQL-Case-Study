"""
Runs the whole case study in one command:

    pip install duckdb pandas matplotlib
    python run_analysis.py

1. downloads the UCI Online Retail data if data/online_retail.csv is missing,
2. runs every SQL file in sql/ in order (DuckDB, no database server needed),
3. saves each named query result to results/<name>.csv,
4. draws the charts in charts/.

Every number in the README and in analysis/key_findings.md comes from results/.
"""

import re
import urllib.request
from pathlib import Path

import duckdb
import matplotlib
import pandas as pd

matplotlib.use("Agg")
matplotlib.rcParams["svg.fonttype"] = "none"   # keep chart text as text (small, sharp SVG)
matplotlib.rcParams["font.family"] = "sans-serif"
import matplotlib.pyplot as plt  # noqa: E402

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data" / "online_retail.csv"
# Same UCI "Online Retail" file (541,909 rows), mirrored as CSV in the
# Databricks "Spark: The Definitive Guide" repository.
DATA_URL = ("https://raw.githubusercontent.com/databricks/Spark-The-Definitive-Guide/"
            "master/data/retail-data/all/online-retail-dataset.csv")

INK, MUTED, GRID = "#0b0b0b", "#898781", "#e1e0d9"
BLUE, ORANGE = "#2a78d6", "#eb6834"


def ensure_data():
    if not DATA.exists():
        DATA.parent.mkdir(exist_ok=True)
        print(f"Downloading data to {DATA} ...")
        urllib.request.urlretrieve(DATA_URL, DATA)


def run_sql(con) -> dict:
    """Run sql/*.sql in order. Each statement starts with '-- name: <name>'."""
    results = {}
    out = ROOT / "results"
    out.mkdir(exist_ok=True)
    for path in sorted((ROOT / "sql").glob("*.sql")):
        parts = re.split(r"^-- name: (\w+)\s*$", path.read_text(encoding="utf-8"), flags=re.M)
        for name, body in zip(parts[1::2], parts[2::2]):
            sql = body.strip().rstrip(";")
            rel = con.sql(sql)
            if rel is not None:                       # a SELECT: keep the result
                df = rel.df()
                df.to_csv(out / f"{name}.csv", index=False)
                results[name] = df
                print(f"  {path.name:<28} {name:<26} {len(df):>4} rows")
    return results


def style(ax, title, subtitle=None):
    ax.set_title(title, loc="left", fontsize=13, fontweight="bold", color=INK, pad=22 if subtitle else 10)
    if subtitle:
        ax.text(0, 1.02, subtitle, transform=ax.transAxes, fontsize=10, color=MUTED)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(GRID)
    ax.tick_params(colors=MUTED, length=0)
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)


def charts(r: dict):
    out = ROOT / "charts"
    out.mkdir(exist_ok=True)

    # 1. Monthly revenue (December 2011 is partial, drawn hollow)
    m = r["monthly_revenue"]
    fig, ax = plt.subplots(figsize=(9, 4))
    full = m[~m["partial_month"]]
    ax.bar(full["month"], full["revenue_gbp"] / 1000, color=BLUE, width=0.7)
    part = m[m["partial_month"]]
    ax.bar(part["month"], part["revenue_gbp"] / 1000, color="white", edgecolor=BLUE, hatch="///", width=0.7)
    peak = full.loc[full["revenue_gbp"].idxmax()]
    ax.annotate(f"£{peak['revenue_gbp'] / 1000:,.0f}k", (peak["month"], peak["revenue_gbp"] / 1000),
                xytext=(0, 4), textcoords="offset points", ha="center", fontsize=9, color=INK)
    style(ax, "Monthly revenue (£ thousand)", "Product sales only. Dec 2011 covers 1–9 Dec (hatched).")
    ax.set_xticks(range(len(m)))
    ax.set_xticklabels([x[2:] for x in m["month"]], fontsize=9)
    fig.tight_layout()
    fig.savefig(out / "monthly_revenue.svg")
    plt.close(fig)

    # 2. RFM: share of customers vs share of revenue per segment
    s = r["rfm_segments"]
    fig, ax = plt.subplots(figsize=(9, 4))
    y = range(len(s))
    ax.barh([i - 0.2 for i in y], s["pct_customers"], height=0.38, color=BLUE, label="% of customers")
    ax.barh([i + 0.2 for i in y], s["pct_revenue"], height=0.38, color=ORANGE, label="% of revenue")
    for i, (c, v) in enumerate(zip(s["pct_customers"], s["pct_revenue"])):
        ax.text(c + 0.6, i - 0.2, f"{c:.0f}%", va="center", fontsize=9, color=INK)
        ax.text(v + 0.6, i + 0.2, f"{v:.0f}%", va="center", fontsize=9, color=INK)
    ax.set_yticks(list(y))
    ax.set_yticklabels(s["segment"], fontsize=10, color=INK)
    ax.invert_yaxis()
    style(ax, "RFM segments: customers vs. revenue", "Segments ordered by revenue")
    ax.grid(axis="y", visible=False)
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.legend(frameon=False, loc="lower right", fontsize=9)
    fig.tight_layout()
    fig.savefig(out / "rfm_segments.svg")
    plt.close(fig)

    # 3. Cohort retention heatmap (months 1-6, one blue ramp)
    c = r["cohort_retention"]
    c = c[~c["in_partial_month"]]          # Dec 2011 has only 9 days of data
    piv = c[c["months_since_first"].between(1, 6)].pivot(index="cohort", columns="months_since_first",
                                                         values="retention_pct")
    piv = piv.dropna(how="all")
    fig, ax = plt.subplots(figsize=(8, 5))
    cmap = matplotlib.colors.LinearSegmentedColormap.from_list("blue", ["#eef4fc", "#9ec5f4", "#2a78d6", "#104281"])
    ax.imshow(piv.values, cmap=cmap, aspect="auto", vmin=0, vmax=50)
    for (i, j), v in pd.DataFrame(piv.values).stack().items():   # empty cells = not observed yet
        if pd.notna(v):
            ax.text(j, i, f"{v:.0f}", ha="center", va="center", fontsize=8.5, color="white" if v > 30 else INK)
    ax.set_xticks(range(piv.shape[1]))
    ax.set_xticklabels([f"+{k}" for k in piv.columns], fontsize=9)
    ax.set_yticks(range(piv.shape[0]))
    ax.set_yticklabels(piv.index, fontsize=9)
    ax.set_title("Share of each cohort buying again (%)", loc="left", fontsize=13, fontweight="bold", color=INK, pad=22)
    ax.text(0, 1.02, "Months after first purchase. Dec 2010 includes older customers; Dec 2011 (9 days) left out.",
            transform=ax.transAxes, fontsize=10, color=MUTED)
    ax.tick_params(length=0, colors=MUTED)
    for sp in ax.spines.values():
        sp.set_visible(False)
    fig.tight_layout()
    fig.savefig(out / "cohort_retention.svg")
    plt.close(fig)


def main():
    ensure_data()
    con = duckdb.connect()
    results = run_sql(con)
    charts(results)
    print("Done: results/ and charts/ updated.")


if __name__ == "__main__":
    main()
