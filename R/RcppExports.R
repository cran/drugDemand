# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#' @title Dosing Date Imputation for Ongoing Patients
#' @description Imputes the dosing dates after cutoff for ongoing
#' patients with dosing records.
#'
#' @param usubjid The unique subject ID.
#' @param V The last dosing visit date relative to randomization.
#' @param C The cutoff date relative to randomization.
#' @param D The discontinuation date relative to randomization.
#' @param model_ki The model for the number of skipped
#'   visits between two consecutive drug dispensing visits.
#'   Options include "constant", "poisson", "zero-inflated poisson",
#'   and "negative binomial".
#' @param theta_ki The model parameters for the number of skipped visits
#'   between two consecutive drug dispensing visits.
#' @param model_ti The model for the gap time between two consecutive
#'   drug dispensing visits. Options include "least squares"
#'   and "least absolute deviations".
#' @param theta_ti The model parameters for the gap time between
#'   two consecutive drug dispensing visits.
#'
#' @return A data frame with two variables:
#'
#' * \code{usubjid}: The unique subject ID.
#'
#' * \code{day}: The dosing visit date relative to randomization.
#'
#' @author Kaifeng Lu, \email{kaifenglu@@gmail.com}
#'
#' @examples
#' set.seed(314)
#'
#' f_dose_ongoing_cpp(
#'   usubjid = "A001", V = 297, C = 329, D = 569,
#'   model_ki = "zero-inflated poisson", theta_ki = c(0.4, 2.5),
#'   model_ti = "least squares", theta_ti = c(21, 2.3))
#'
#' @export
f_dose_ongoing_cpp <- function(usubjid, V, C, D, model_ki, theta_ki, model_ti, theta_ti) {
    .Call(`_drugDemand_f_dose_ongoing_cpp`, usubjid, V, C, D, model_ki, theta_ki, model_ti, theta_ti)
}

#' @title Dosing Date Imputation for New Patients
#' @description Imputes the dosing dates for new patients and ongoing
#' patients with no dosing records.
#'
#' @param usubjid The unique subject ID.
#' @param V Initialized to 0 and corresponds to the randomization visit.
#' @param C The cutoff date relative to randomization.
#' @param D The discontinuation date relative to randomization.
#' @param model_k0 The model for the number of skipped
#'   visits between randomization and the first drug dispensing visit.
#'   Options include "constant", "poisson", "zero-inflated poisson",
#'   and "negative binomial".
#' @param theta_k0 The model parameters for the number of skipped
#'   visits between randomization and the first drug dispensing visit.
#' @param model_t0 The model for the gap time between randomization
#'   and the first drug dispensing visit when there is no visit skipping.
#'   Options include "constant", "exponential", "weibull",
#'   "log-logistic", and "log-normal".
#' @param theta_t0 The model parameters for the gap time between
#'   randomization and the first drug dispensing visit when there is
#'   no visit skipping.
#' @param model_t1 The model for the gap time between randomization
#'   and the first drug dispensing visit when there is visit skipping.
#'   Options include "least squares", and "least absolute deviations".
#' @param theta_t1 The model parameters for the gap time between
#'   randomization and the first drug dispensing visit when there is
#'   visit skipping.
#' @param model_ki The model for the number of skipped
#'   visits between two consecutive drug dispensing visits.
#'   Options include "constant", "poisson", "zero-inflated poisson",
#'   and "negative binomial".
#' @param theta_ki The model parameters for the number of skipped
#'   visits between two consecutive drug dispensing visits.
#' @param model_ti The model for the gap time between two consecutive
#'   drug dispensing visits. Options include "least squares"
#'   and "least absolute deviations".
#' @param theta_ti The model parameters for the gap time between
#'   two consecutive drug dispensing visits.
#'
#' @return A data frame with two variables:
#'
#' * \code{usubjid}: The unique subject ID.
#'
#' * \code{day}: The dosing visit date relative to randomization.
#'
#' @author Kaifeng Lu, \email{kaifenglu@@gmail.com}
#'
#' @examples
#' set.seed(529)
#'
#' f_dose_new_cpp(
#'   usubjid = "Z001", V = 0, C = 87, D = 985,
#'   model_k0 = "zero-inflated poisson", theta_k0 = c(0.6, 1.1),
#'   model_t0 = "log-logistic", theta_t0 = c(-1.0, 0.7),
#'   model_t1 = "least squares", theta_t1 = c(21.5, 1.9),
#'   model_ki = "zero-inflated poisson", theta_ki = c(0.1, 0.4),
#'   model_ti = "least squares", theta_ti = c(21, 2.3))
#'
#' @export
f_dose_new_cpp <- function(usubjid, V, C, D, model_k0, theta_k0, model_t0, theta_t0, model_t1, theta_t1, model_ki, theta_ki, model_ti, theta_ti) {
    .Call(`_drugDemand_f_dose_new_cpp`, usubjid, V, C, D, model_k0, theta_k0, model_t0, theta_t0, model_t1, theta_t1, model_ki, theta_ki, model_ti, theta_ti)
}

norm_rej <- function(a, b) {
    .Call(`_drugDemand_norm_rej`, a, b)
}

unif_rej <- function(a, b) {
    .Call(`_drugDemand_unif_rej`, a, b)
}

halfnorm_rej <- function(a, b) {
    .Call(`_drugDemand_halfnorm_rej`, a, b)
}

exp_rej <- function(a, b) {
    .Call(`_drugDemand_exp_rej`, a, b)
}

rtnormcpp <- function(mean, sd, lower, upper) {
    .Call(`_drugDemand_rtnormcpp`, mean, sd, lower, upper)
}

