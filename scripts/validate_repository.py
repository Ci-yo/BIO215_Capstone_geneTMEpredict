from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
MODELS = [
    "inst/extdata/rf_celltype.rds",
    "inst/extdata/rf_disease_basic.rds",
    "inst/extdata/rf_disease_ct.rds",
]
REQUIRED = [
    "DESCRIPTION",
    "NAMESPACE",
    "R/main.R",
    "inst/extdata/gene_input_example.csv",
    "figs/feature_importance_celltype.png",
    "figs/shap_beeswarm_cancer.png",
    "figs/rocpr_disease_modelA_scores.png",
    *MODELS,
]

missing = [name for name in REQUIRED if not (ROOT / name).is_file()]
assert not missing, f"Missing package files: {missing}"

description = (ROOT / "DESCRIPTION").read_text(encoding="utf-8")
assert "BIO215_Capstone_geneTMEpredict" in description, "Repository URL is stale"
assert "Ci-yo@users.noreply.github.com" in description, "Public maintainer email is missing"
assert "MIT + file LICENSE" in description, "License metadata is missing"

namespace = (ROOT / "NAMESPACE").read_text(encoding="utf-8")
expected_exports = {
    "predict_celltype_rf",
    "predict_disease_basic_rf",
    "predict_tme_all",
}
exports = set(re.findall(r"export\(([^)]+)\)", namespace))
assert expected_exports.issubset(exports), f"Missing exports: {sorted(expected_exports - exports)}"

source = (ROOT / "R/main.R").read_text(encoding="utf-8")
for function in expected_exports:
    assert re.search(rf"{function}\s*<-\s*function", source), f"Missing implementation: {function}"
assert all((ROOT / model).stat().st_size > 10_000 for model in MODELS), "Bundled model is unexpectedly small"

for forbidden in (".Rhistory", ".RData", ".Renviron", "README.html"):
    assert not (ROOT / forbidden).exists(), f"Remove generated/local file: {forbidden}"

print("OK: package metadata, three exported functions, three models and figures validated")
