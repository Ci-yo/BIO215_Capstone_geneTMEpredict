<div align="center">

# geneTMEpredict

**A reusable R model engine for synthetic tumour-microenvironment classification**

[![Repository checks](https://github.com/Ci-yo/BIO215_Capstone_geneTMEpredict/actions/workflows/repository-check.yml/badge.svg)](https://github.com/Ci-yo/BIO215_Capstone_geneTMEpredict/actions/workflows/repository-check.yml)
![R package](https://img.shields.io/badge/R-package-276DC3?logo=r&logoColor=white)
![Models](https://img.shields.io/badge/Random%20Forest-models%203-2E8B57)
![License](https://img.shields.io/badge/license-MIT-555555)
![Course](https://img.shields.io/badge/BIO215-Capstone-4C566A)

<img src="figs/feature_importance_celltype.png" width="760" alt="Feature importance for cell type classification">

<sub>The model layer behind TME Explorer: cell type, disease state and a context-aware combined prediction.</sub>

</div>

## Package at a glance

`geneTMEpredict` turns three trained Random Forest models into a small, documented prediction API. It accepts synthetic scRNA-seq-style gene and pathway features and returns cell-type and tumour-state classifications in analysis-ready tables.

| Function | Model task | Output |
|---|---|---|
| `predict_celltype_rf()` | `Cancer` / `T_Cell` / `Fibroblast` | cell-type factor |
| `predict_disease_basic_rf()` | `Tumor` / `Healthy_Control` | disease-state factor |
| `predict_tme_all()` | run all three bundled models | input + three prediction columns |

The interactive companion is [`TME Explorer`](https://github.com/Ci-yo/BIO215_Capstone_TME-Shiny), a separate Shiny repository for exploration, upload workflows and gene-level “what-if” experiments.

## Install

```r
install.packages("remotes")
remotes::install_github("Ci-yo/BIO215_Capstone_geneTMEpredict")
library(geneTMEpredict)
```

## Quick start

```r
example_path <- system.file(
  "extdata", "gene_input_example.csv",
  package = "geneTMEpredict"
)
cells <- read.csv(example_path)

result <- predict_tme_all(cells)
result[c("pred_Cell_Type", "pred_Disease_basic", "pred_Disease_with_CT")]
```

Input requires six numeric features:

```text
Gene_E_Housekeeping, Gene_A_Oncogene, Gene_B_Immune,
Gene_C_Stromal, Gene_D_Therapy, Pathway_Score_Inflam
```

## Model architecture

```mermaid
flowchart LR
    A[Six expression/pathway features] --> B[Cell-type model]
    A --> C[Engineered TME scores]
    C --> D[Basic disease model]
    B --> E[Cell-type-informed disease model]
    A --> E
    B --> F[Unified result table]
    D --> F
    E --> F
```

The basic disease model adds three deterministic features: `Tumor_score`, `Immune_score` and `Stromal_score`. The third model tests whether predicted cellular identity adds context to disease-state classification.

## Evidence, not just endpoints

<table>
  <tr>
    <td width="50%" align="center"><img src="figs/shap_beeswarm_cancer.png" alt="SHAP summary for cancer probability"><br><strong>Local and global signal</strong><br>SHAP distribution for the cancer class.</td>
    <td width="50%" align="center"><img src="figs/rocpr_disease_modelA_scores.png" alt="ROC and PR curves for disease model"><br><strong>Disease-model performance</strong><br>ROC and precision–recall views after score engineering.</td>
  </tr>
</table>

## Repository guide

```text
BIO215_Capstone_geneTMEpredict/
├── R/                 exported prediction API
├── man/               generated function documentation
├── inst/extdata/      three models and example input
├── figs/              model interpretation and evaluation
├── scripts/           dependency-free package archive check
└── DESCRIPTION        package metadata and dependencies
```

Run the same repository-level check used by GitHub Actions:

```bash
python scripts/validate_repository.py
```

## Scope and responsible use

The training data are fully synthetic. This makes the project useful for teaching model packaging, interpretation and deployment, but it does **not** establish clinical validity. Outputs are demonstrations, not patient-level predictions.

The package is licensed under MIT.

> **Academic-use note**  
> This is a completed coursework portfolio project. Follow your institution's academic-integrity rules when reusing it.
