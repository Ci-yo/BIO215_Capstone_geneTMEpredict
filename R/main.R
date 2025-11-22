#' Predict cell type from gene-expression features
#'
#' @description
#' Predicts the cell type (Cancer / T_Cell / Fibroblast) for one or
#' multiple samples using the pre-trained random forest model.
#'
#' @param newdata A data.frame containing at least the following numeric
#'   columns:
#'   \itemize{
#'     \item Gene_E_Housekeeping
#'     \item Gene_A_Oncogene
#'     \item Gene_B_Immune
#'     \item Gene_C_Stromal
#'     \item Gene_D_Therapy
#'     \item Pathway_Score_Inflam
#'   }
#'
#' @return A factor vector of predicted cell types.
#'
#' @examples
#' path <- system.file("extdata", "gene_input_example.csv",
#'                     package = "geneTMEpredict")
#' ex_df <- read.csv(path)
#' head(predict_celltype_rf(ex_df))
#'
#' @export
predict_celltype_rf <- function(newdata) {
  required_cols <- c(
    "Gene_E_Housekeeping",
    "Gene_A_Oncogene",
    "Gene_B_Immune",
    "Gene_C_Stromal",
    "Gene_D_Therapy",
    "Pathway_Score_Inflam"
  )

  missing_cols <- setdiff(required_cols, colnames(newdata))
  if (length(missing_cols) > 0L) {
    stop("newdata is missing required columns: ",
         paste(missing_cols, collapse = ", "))
  }

  # 只取需要的列，并保证是数值
  X <- newdata[, required_cols]
  X[] <- lapply(X, as.numeric)

  # 从包的 extdata 中加载模型
  model_path <- system.file(
    "extdata", "rf_celltype.rds", package = "geneTMEpredict"
  )
  if (model_path == "") {
    stop("Cannot find rf_celltype.rds in extdata of geneTMEpredict.")
  }
  rf_model <- readRDS(model_path)

  preds <- predict(rf_model, newdata = X, type = "class")
  return(preds)
}


#' Predict disease status using gene + pathway scores
#'
#' @description
#' Predicts disease status (Healthy_Control / Tumor) from gene-expression
#' features. Internally, tumor / immune / stromal scores are computed
#' to match the training model.
#'
#' @inheritParams predict_celltype_rf
#'
#' @return A factor vector of predicted disease status.
#'
#' @examples
#' path <- system.file("extdata", "gene_input_example.csv",
#'                     package = "geneTMEpredict")
#' ex_df <- read.csv(path)
#' head(predict_disease_basic_rf(ex_df))
#'
#' @export
predict_disease_basic_rf <- function(newdata) {
  required_cols <- c(
    "Gene_E_Housekeeping",
    "Gene_A_Oncogene",
    "Gene_B_Immune",
    "Gene_C_Stromal",
    "Gene_D_Therapy",
    "Pathway_Score_Inflam"
  )

  missing_cols <- setdiff(required_cols, colnames(newdata))
  if (length(missing_cols) > 0L) {
    stop("newdata is missing required columns: ",
         paste(missing_cols, collapse = ", "))
  }

  X <- newdata[, required_cols]
  X[] <- lapply(X, as.numeric)

  # 计算与训练脚本一致的 score
  X$Tumor_score   <- X$Gene_A_Oncogene + X$Gene_D_Therapy
  X$Immune_score  <- X$Gene_B_Immune   + X$Pathway_Score_Inflam
  X$Stromal_score <- X$Gene_C_Stromal

  model_path <- system.file(
    "extdata", "rf_disease_basic.rds", package = "geneTMEpredict"
  )
  if (model_path == "") {
    stop("Cannot find rf_disease_basic.rds in extdata of geneTMEpredict.")
  }
  rf_model <- readRDS(model_path)

  preds <- predict(rf_model, newdata = X, type = "class")
  return(preds)
}


#' Joint prediction of cell type and disease status
#'
#' @description
#' Convenience wrapper that returns both cell-type predictions and
#' disease status predictions (using both the basic model and the
#' Cell_Type-informed model).
#'
#' @inheritParams predict_celltype_rf
#'
#' @return A data.frame with the original rows of \code{newdata} and the
#'   following additional columns:
#'   \itemize{
#'     \item pred_Cell_Type
#'     \item pred_Disease_basic
#'     \item pred_Disease_with_CT
#'   }
#'
#' @examples
#' path <- system.file("extdata", "gene_input_example.csv",
#'                     package = "geneTMEpredict")
#' ex_df <- read.csv(path)
#' head(predict_tme_all(ex_df))
#'
#' @export
predict_tme_all <- function(newdata) {
  # 先预测细胞类型
  pred_ct <- predict_celltype_rf(newdata)

  # 用 basic 模型预测疾病
  pred_disease_basic <- predict_disease_basic_rf(newdata)

  # 用带 Cell_Type 的模型再预测一次疾病
  required_cols <- c(
    "Gene_E_Housekeeping",
    "Gene_A_Oncogene",
    "Gene_B_Immune",
    "Gene_C_Stromal",
    "Gene_D_Therapy",
    "Pathway_Score_Inflam"
  )

  X <- newdata[, required_cols]
  X[] <- lapply(X, as.numeric)
  X$Cell_Type <- factor(
    pred_ct,
    levels = c("Cancer", "T_Cell", "Fibroblast")
  )

  model_path_ct <- system.file(
    "extdata", "rf_disease_ct.rds", package = "geneTMEpredict"
  )
  if (model_path_ct == "") {
    stop("Cannot find rf_disease_ct.rds in extdata of geneTMEpredict.")
  }
  rf_ct <- readRDS(model_path_ct)

  pred_disease_ct <- predict(rf_ct, newdata = X, type = "class")

  # 组合结果
  out <- newdata
  out$pred_Cell_Type        <- pred_ct
  out$pred_Disease_basic    <- pred_disease_basic
  out$pred_Disease_with_CT  <- pred_disease_ct

  out
}
