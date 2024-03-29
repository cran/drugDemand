#' @title Drug Dispensing Visit Dates Simulation for One Iteration
#' @description Simulates drug dispensing visit dates for one iteration.
#'
#' @param i The iteration number.
#' @param k0_fit The model fit for the number of skipped
#' visits between randomization and the first drug dispensing visit.
#' @param t0_fit The model fit for the gap time between randomization
#' and the first drug dispensing visit when there is no visit skipping.
#' @param t1_fit The model fit for the gap time between randomization
#' and the first drug dispensing visit when there is visit skipping.
#' @param ki_fit The model fit for the number of skipped
#' visits between two consecutive drug dispensing visits.
#' @param ti_fit The model fit for the gap time between two
#' consecutive drug dispensing visits.
#' @param vf_ongoing1 A data frame for the last observed drug dispensing
#'   date for ongoing patients with drug dispensing records.
#'   For the common time model, it includes the following variables:
#'   \code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, \code{totalTime},
#'   \code{V}, \code{C}, and \code{D}.
#'   For separate time models, it includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{arrivalTime}, \code{treatment}, \code{treatment_description},
#'   \code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.
#' @param vf_new1 A data frame for the randomization date for new patients
#'   and ongoing patients with no drug dispensing records.
#'   For the common time model, it includes the following variables:
#'   \code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, \code{totalTime},
#'   \code{V}, \code{C}, and \code{D}.
#'   For separate time models, it includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{arrivalTime}, \code{treatment}, \code{treatment_description},
#'   \code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.
#'
#' @return A data frame containing the simulated drug dispensing visit
#' dates at the subject level for ongoing and new subjects. It includes
#' the following variables:
#' \code{usubjid}, \code{day}, \code{draw}, \code{arrivalTime},
#' \code{treatment}, \code{treatment_description}, \code{time},
#' \code{totalTime}, and \code{status}.
#'
#' @author Kaifeng Lu, \email{kaifenglu@@gmail.com}
#'
#' @seealso \code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
#' \code{\link{f_fit_ti}}
#'
#' @examples
#'
#' \donttest{
#' set.seed(431)
#' library(dplyr)
#'
#' pred <- eventPred::getPrediction(
#'   df = df2,
#'   to_predict = "event only",
#'   target_d = 250,
#'   event_model = "log-logistic",
#'   dropout_model = "none",
#'   pilevel = 0.95,
#'   nyears = 3,
#'   nreps = 200,
#'   showsummary = FALSE,
#'   showplot = FALSE,
#'   by_treatment = TRUE)
#'
#' observed <- f_dose_observed(df2, visitview2, showplot = FALSE)
#'
#' fit <- f_dispensing_models(
#'   observed$vf, dosing_schedule_df,
#'   model_k0 = "zero-inflated poisson",
#'   model_t0 = "log-logistic",
#'   model_t1 = "least squares",
#'   model_ki = "zero-inflated poisson",
#'   model_ti = "least squares",
#'   model_di = "linear mixed-effects model",
#'   nreps = 200, showplot = FALSE)
#'
#' trialsdt = df2$trialsdt[1]
#' cutoffdt = df2$cutoffdt[1]
#' t0 = as.numeric(cutoffdt - trialsdt + 1)
#' nyears = 3
#' t1 = t0 + nyears*365
#'
#' vf_ongoing_new <- f_ongoing_new(
#'   pred$event_pred$newEvents,
#'   observed$kit_description_df,
#'   observed$treatment_by_drug_df,
#'   observed$vf)
#'
#' vf_ongoing <- vf_ongoing_new$vf_ongoing
#' vf_new <- vf_ongoing_new$vf_new
#'
#' vf_ongoing1 <- vf_ongoing %>%
#'   group_by(draw, usubjid) %>%
#'   slice(n()) %>%
#'   mutate(V = day - 1,
#'          C = as.numeric(t0 - arrivalTime),
#'          D = pmin(time - 1, t1 - arrivalTime)) %>%
#'   select(-c("kit", "kit_name", "day", "dose"))
#'
#' ### new patients and ongoing patients with no dosing records ###
#' vf_new1 <- vf_new %>%
#'   group_by(draw, usubjid) %>%
#'   slice(n()) %>%
#'   mutate(V = 0,
#'          C = as.numeric(t0 - arrivalTime),
#'          D = pmin(time - 1, t1 - arrivalTime)) %>%
#'   select(-c("kit", "kit_name"))
#'
#' dosing_subject_new1 <- f_dose_draw_t_1(
#'   1, fit$k0_fit, fit$t0_fit, fit$t1_fit,
#'   fit$ki_fit, fit$ti_fit, vf_ongoing1, vf_new1)
#'
#' head(dosing_subject_new1)
#' }
#'
#' @export
f_dose_draw_t_1 <- function(
    i, k0_fit, t0_fit, t1_fit, ki_fit, ti_fit,
    vf_ongoing1, vf_new1) {

  model_k0 = tolower(k0_fit$fit$model)
  if (model_k0 == "constant") {
    theta_k0 = k0_fit$theta[i]
  } else if (model_k0 == "poisson") {
    theta_k0 = exp(k0_fit$theta[i])
  } else if (model_k0 == "zero-inflated poisson") {
    theta_k0 = c(plogis(k0_fit$theta[i,2]), exp(k0_fit$theta[i,1]))
  } else if (model_k0 == "negative binomial") {
    mu = exp(k0_fit$theta[i,1])
    size = exp(k0_fit$theta[i,2])
    prob = size/(size + mu)
    theta_k0 = c(size, prob)
  }

  model_t0 = tolower(t0_fit$fit$model)
  if (model_t0 == "constant") {
    theta_t0 = t0_fit$theta[i]
  } else if (model_t0 == "exponential") {
    theta_t0 = exp(t0_fit$theta[i])
  } else if (model_t0 == "weibull") {
    theta_t0 = c(exp(-t0_fit$theta[i,2]), exp(t0_fit$theta[i,1]))
  } else if (model_t0 == "log-logistic") {
    theta_t0 = c(t0_fit$theta[i,1], exp(t0_fit$theta[i,2]))
  } else if (model_t0 == "log-normal") {
    theta_t0 = c(t0_fit$theta[i,1], exp(t0_fit$theta[i,2]))
  }

  model_t1 = tolower(t1_fit$fit$model)
  theta_t1 = c(t1_fit$theta[i,1], t1_fit$theta[i,2]) # beta and sigma

  model_ki = tolower(ki_fit$fit$model)
  if (model_ki == "constant") {
    theta_ki = ki_fit$theta[i]
  } else if (model_ki == "poisson") {
    theta_ki = exp(ki_fit$theta[i])
  } else if (model_ki == "zero-inflated poisson") {
    theta_ki = c(plogis(ki_fit$theta[i,2]), exp(ki_fit$theta[i,1]))
  } else if (model_ki == "negative binomial") {
    mu = exp(ki_fit$theta[i,1])
    size = exp(ki_fit$theta[i,2])
    prob = size/(size + mu)
    theta_ki = c(size, prob)
  }

  model_ti = tolower(ti_fit$fit$model)
  theta_ti = c(ti_fit$theta[i,1], ti_fit$theta[i,2])

  # impute dosing for ongoing patients
  df_ongoing1 <- vf_ongoing1 %>% filter(.data$draw == i)

  # impute dosing dates for these ongoing patients
  df_ongoingi <- f_dose_ongoing_cpp(
    df_ongoing1$usubjid, df_ongoing1$V, df_ongoing1$C, df_ongoing1$D,
    model_ki, theta_ki, model_ti, theta_ti)

  # get other variables and combine with observed drug dispensing data
  df_ongoingi <- df_ongoingi %>%
    left_join(df_ongoing1 %>% select(-c("V", "C", "D")), by = "usubjid") %>%
    mutate(status = "ongoing")

  # impute dosing for new patients
  if (!is.null(vf_new1)) {
    # dosing data for new patients in draw i
    df_new1 <- vf_new1 %>% filter(.data$draw == i)

    # impute dosing data for new patients
    df_newi <- f_dose_new_cpp(
      df_new1$usubjid, df_new1$V, df_new1$C, df_new1$D,
      model_k0, theta_k0, model_t0, theta_t0, model_t1, theta_t1,
      model_ki, theta_ki, model_ti, theta_ti)

    # get other variables
    df_newi <- df_newi %>%
      left_join(df_new1 %>% select(-c("V", "C", "D")), by = "usubjid") %>%
      mutate(status = "new")
  }

  # combine drug dispensing dates from ongoing and new patients
  if (is.null(vf_new1)) {  # real-time after enrollment completion
    df_ongoingi
  } else { # real-time before enrollment completion
    bind_rows(df_ongoingi, df_newi)
  }
}


#' @title Drug Dispensing Data Simulation for One Iteration
#' @description Simulates drug dispensing data for one iteration.
#'
#' @param i The iteration number.
#' @param common_time_model A Boolean variable that indicates whether
#'   a common time model is used for drug dispensing visits.
#' @param k0_fit The model fit for the number of skipped
#'   visits between randomization and the first drug dispensing visit.
#' @param t0_fit The model fit for the gap time between randomization
#'   and the first drug dispensing visit when there is no visit skipping.
#' @param t1_fit The model fit for the gap time between randomization
#'   and the first drug dispensing visit when there is visit skipping.
#' @param ki_fit The model fit for the number of skipped
#'   visits between two consecutive drug dispensing visits.
#' @param ti_fit The model fit for the gap time between two
#'   consecutive drug dispensing visits.
#' @param di_fit The model fit for the dispensed doses at drug
#'   dispensing visits.
#' @param vf_ongoing A data frame for the observed drug dispensing
#'   data for ongoing patients with drug dispensing records.
#'   It includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{day}, \code{dose}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, and \code{totalTime}.
#' @param vf_ongoing1 A data frame for the last observed drug dispensing
#'   date for ongoing patients with drug dispensing records.
#'   For the common time model, it includes the following variables:
#'   \code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, \code{totalTime},
#'   \code{V}, \code{C}, and \code{D}.
#'   For separate time models, it includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{arrivalTime}, \code{treatment}, \code{treatment_description},
#'   \code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.
#' @param vf_new A data frame for the randomization date for new
#'   patients and ongoing patients with no drug dispensing records.
#'   It includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{arrivalTime}, \code{treatment}, \code{treatment_description},
#'   \code{time}, and \code{totalTime}.
#' @param vf_new1 A data frame for the randomization date for new patients
#'   and ongoing patients with no drug dispensing records.
#'   For the common time model, it includes the following variables:
#'   \code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, \code{totalTime},
#'   \code{V}, \code{C}, and \code{D}.
#'   For separate time models, it includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{arrivalTime}, \code{treatment}, \code{treatment_description},
#'   \code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.
#' @param vf_kit A data frame indicating the kit names for each subject
#'   by draw. It includes the following variables:
#'   \code{draw}, \code{usubjid}, \code{kit}, and \code{kit_name}.
#' @param l Number of kit types.
#' @param t A vector of new time points for drug dispensing prediction.
#'
#' @return A list of two components:
#'
#' * \code{dosing_subject_newi}: A data frame for the drug dispensing
#'   data at the subject level by date for ongoing and new subjects
#'   for the given iteration. It contains the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{day}, \code{dose}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, and \code{totalTime}.
#'
#' * \code{dosing_summary_newi}: A data frame for the drug dispensing
#'   summary data by drug, time, and simulation draw for ongoing and
#'   new subjects for the given iteration. It includes the following
#'   variables:
#'   \code{kit}, \code{kit_name}, \code{t}, \code{draw}, and
#'   \code{total_dose_b}.
#'
#' @author Kaifeng Lu, \email{kaifenglu@@gmail.com}
#'
#' @seealso \code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
#' \code{\link{f_fit_ti}}, \code{\link{f_fit_di}}
#'
#' @examples
#'
#' \donttest{
#' set.seed(431)
#' library(dplyr)
#'
#' pred <- eventPred::getPrediction(
#'   df = df2,
#'   to_predict = "event only",
#'   target_d = 250,
#'   event_model = "log-logistic",
#'   dropout_model = "none",
#'   pilevel = 0.95,
#'   nyears = 3,
#'   nreps = 200,
#'   showsummary = FALSE,
#'   showplot = FALSE,
#'   by_treatment = TRUE)
#'
#' observed <- f_dose_observed(df2, visitview2, showplot = FALSE)
#'
#' fit <- f_dispensing_models(
#'   observed$vf, dosing_schedule_df,
#'   model_k0 = "zero-inflated poisson",
#'   model_t0 = "log-logistic",
#'   model_t1 = "least squares",
#'   model_ki = "zero-inflated poisson",
#'   model_ti = "least squares",
#'   model_di = "linear mixed-effects model",
#'   nreps = 200, showplot = FALSE)
#'
#' trialsdt = df2$trialsdt[1]
#' cutoffdt = df2$cutoffdt[1]
#' t0 = as.numeric(cutoffdt - trialsdt + 1)
#' nyears = 3
#' t1 = t0 + nyears*365
#' t = c(seq(t0, t1, 30), t1)
#'
#' l = nrow(observed$kit_description_df)
#'
#' vf_ongoing_new <- f_ongoing_new(
#'   pred$event_pred$newEvents,
#'   observed$kit_description_df,
#'   observed$treatment_by_drug_df,
#'   observed$vf)
#'
#' vf_ongoing <- vf_ongoing_new$vf_ongoing
#' vf_new <- vf_ongoing_new$vf_new
#'
#' vf_kit <- vf_ongoing %>%
#'   select(-c("day", "dose")) %>%
#'   bind_rows(vf_new) %>%
#'   group_by(draw, usubjid, kit, kit_name) %>%
#'   slice(1) %>%
#'   select(c("draw", "usubjid", "kit", "kit_name"))
#'
#' vf_ongoing1 <- vf_ongoing %>%
#'   group_by(draw, usubjid) %>%
#'   slice(n()) %>%
#'   mutate(V = day - 1,
#'          C = as.numeric(t0 - arrivalTime),
#'          D = pmin(time - 1, t1 - arrivalTime)) %>%
#'   select(-c("kit", "kit_name", "day", "dose"))
#'
#' ### new patients and ongoing patients with no dosing records ###
#' vf_new1 <- vf_new %>%
#'   group_by(draw, usubjid) %>%
#'   slice(n()) %>%
#'   mutate(V = 0,
#'          C = as.numeric(t0 - arrivalTime),
#'          D = pmin(time - 1, t1 - arrivalTime)) %>%
#'   select(-c("kit", "kit_name"))
#'
#' # first iteration to extract subject and summary data
#' list1 <- f_dose_draw_1(
#'   1, fit$common_time_model,
#'   fit$k0_fit, fit$t0_fit, fit$t1_fit,
#'   fit$ki_fit, fit$ti_fit, fit$di_fit,
#'   vf_ongoing, vf_ongoing1, vf_new, vf_new1,
#'   vf_kit, l, t)
#'
#' head(list1$dosing_subject_newi)
#' head(list1$dosing_summary_newi)
#' }
#'
#' @export
f_dose_draw_1 <- function(
    i, common_time_model,
    k0_fit, t0_fit, t1_fit, ki_fit, ti_fit, di_fit,
    vf_ongoing, vf_ongoing1, vf_new, vf_new1,
    vf_kit, l, t) {

  # impute drug dispensing visit dates
  if (common_time_model) {
    dosing_subject_new1 <- f_dose_draw_t_1(
      i, k0_fit, t0_fit, t1_fit, ki_fit, ti_fit,
      vf_ongoing1, vf_new1)

    # add kit information for each subject
    dosing_subject_new2 <- dosing_subject_new1 %>%
      left_join(vf_kit %>% filter(.data$draw == i),
                by = c("draw", "usubjid"),
                multiple = "all",
                relationship = "many-to-many")
  } else {
    dosing_subject_new2 <- purrr::map_dfr(
      1:l, function(h) {
        f_dose_draw_t_1(
          i, k0_fit[[h]], t0_fit[[h]], t1_fit[[h]],
          ki_fit[[h]], ti_fit[[h]],
          vf_ongoing1 %>% filter(.data$kit == h),
          vf_new1 %>% filter(.data$kit == h))
      })
  }

  # impute doses to dispense
  dosing_subject_new3 <- purrr::map_dfr(
    1:l, function(h) {
      mud = di_fit[[h]]$theta$fixed[i,1]
      sigmab = di_fit[[h]]$theta$fixed[i,2]
      sigmae = di_fit[[h]]$theta$fixed[i,3]
      df_ran = tibble(usubjid = di_fit[[h]]$theta$usubjid,
                      b1 = di_fit[[h]]$theta$random[i,])

      df_ongoing2 <- dosing_subject_new2 %>%
        filter(.data$kit == h & .data$status == "ongoing") %>%
        inner_join(df_ran, by = "usubjid")

      df_ongoing2$dose <- pmax(round(rnorm(nrow(df_ongoing2))*sigmae +
                                       mud + df_ongoing2$b1), 1.0)

      df_new2 <- dosing_subject_new2 %>%
        filter(.data$kit == h & .data$status == "new")
      n_new = nrow(df_new2)

      if (n_new > 0) {
        df_new2$b1 = rnorm(n_new)*sigmab
        df_new2$dose <- pmax(round(rnorm(n_new)*sigmae +
                                     mud + df_new2$b1), 1.0)
      }

      if (n_new == 0) {
        df_ongoing2
      } else {
        bind_rows(df_ongoing2, df_new2)
      }
    })

  # add observed drug dispensing data
  dosing_subject_newi <- vf_ongoing %>%
    filter(.data$draw == i) %>%
    bind_rows(dosing_subject_new3 %>% select(-c("status", "b1")))

  # drug dispensed for ongoing and new subjects by kit, t, and draw
  dosing_summary_newi <- tibble(t = t) %>%
    cross_join(dosing_subject_newi) %>%
    filter(.data$arrivalTime + .data$day - 1 <= .data$t) %>%
    group_by(.data$kit, .data$kit_name, .data$t, .data$draw) %>%
    summarise(total_dose_b = sum(.data$dose), .groups = "drop_last")

  # output drug dispensing data at the subject and summary levels
  list(dosing_subject_newi = dosing_subject_newi,
       dosing_summary_newi = dosing_summary_newi)
}


#' @title Drug Dispensing Data Simulation
#' @description Simulates drug dispensing data after cutoff for
#' both ongoing and new patients.
#'
#' @param vf_ongoing A data frame for the observed drug dispensing
#'   data for ongoing patients with drug dispensing records.
#'   It includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{day}, \code{dose}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, and \code{totalTime}.
#' @param vf_new A data frame for the randomization date for new
#'   patients and ongoing patients with no drug dispensing records.
#'   It includes the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{arrivalTime}, \code{treatment}, \code{treatment_description},
#'   \code{time}, and \code{totalTime}.
#' @param common_time_model A Boolean variable that indicates whether
#'   a common time model is used for drug dispensing visits.
#' @param k0_fit The model fit for the number of skipped
#'   visits between randomization and the first drug dispensing visit.
#' @param t0_fit The model fit for the gap time between randomization
#'   and the first drug dispensing visit when there is no visit skipping.
#' @param t1_fit The model fit for the gap time between randomization
#'   and the first drug dispensing visit when there is visit skipping.
#' @param ki_fit The model fit for the number of skipped
#'   visits between two consecutive drug dispensing visits.
#' @param ti_fit The model fit for the gap time between two
#'   consecutive drug dispensing visits.
#' @param di_fit The model fit for the dispensed doses at drug
#'   dispensing visits.
#' @param t0 The cutoff date relative to the trial start date.
#' @param t A vector of new time points for drug dispensing prediction.
#' @param ncores_max The maximum number of cores to use for parallel
#'   computing. The actual number of cores used is the minimum of
#'   \code{ncores_max} and half of the detected number of cores.
#'
#' @return A list with two components:
#'
#' * \code{dosing_subject_new}: A data frame containing observed and
#'   imputed subject-level dosing records for ongoing and new patients
#'   for the first iteration. It contains the following variables:
#'   \code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
#'   \code{day}, \code{dose}, \code{arrivalTime}, \code{treatment},
#'   \code{treatment_description}, \code{time}, and \code{totalTime}.
#'
#' * \code{dosing_summary_new}: A data frame providing dosing summaries
#'   by drug, future time point, and simulation draw for ongoing
#'   and new patients. It contains the following variables:
#'   \code{kit}, \code{kit_name}, \code{t}, \code{draw}, and
#'   \code{total_dose_b}.
#'
#' @author Kaifeng Lu, \email{kaifenglu@@gmail.com}
#'
#' @seealso \code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
#' \code{\link{f_fit_ti}}, \code{\link{f_fit_di}}
#'
#' @examples
#'
#' \donttest{
#' set.seed(431)
#' library(dplyr)
#'
#' pred <- eventPred::getPrediction(
#'   df = df2,
#'   to_predict = "event only",
#'   target_d = 250,
#'   event_model = "log-logistic",
#'   dropout_model = "none",
#'   pilevel = 0.95,
#'   nyears = 3,
#'   nreps = 200,
#'   showsummary = FALSE,
#'   showplot = FALSE,
#'   by_treatment = TRUE)
#'
#' observed <- f_dose_observed(df2, visitview2, showplot = FALSE)
#'
#' fit <- f_dispensing_models(
#'   observed$vf, dosing_schedule_df,
#'   model_k0 = "zero-inflated poisson",
#'   model_t0 = "log-logistic",
#'   model_t1 = "least squares",
#'   model_ki = "zero-inflated poisson",
#'   model_ti = "least squares",
#'   model_di = "linear mixed-effects model",
#'   nreps = 200, showplot = FALSE)
#'
#' trialsdt = df2$trialsdt[1]
#' cutoffdt = df2$cutoffdt[1]
#' t0 = as.numeric(cutoffdt - trialsdt + 1)
#' nyears = 3
#' t1 = t0 + nyears*365
#' t = c(seq(t0, t1, 30), t1)
#'
#' vf_ongoing_new <- f_ongoing_new(
#'   pred$event_pred$newEvents,
#'   observed$kit_description_df,
#'   observed$treatment_by_drug_df,
#'   observed$vf)
#'
#' dose_draw <- f_dose_draw(
#'   vf_ongoing_new$vf_ongoing,
#'   vf_ongoing_new$vf_new,
#'   fit$common_time_model,
#'   fit$k0_fit, fit$t0_fit, fit$t1_fit,
#'   fit$ki_fit, fit$ti_fit, fit$di_fit,
#'   t0, t, ncores_max = 2)
#'
#' head(dose_draw$dosing_subject_new)
#' head(dose_draw$dosing_summary_new)
#' }
#'
#' @export
f_dose_draw <- function(
    vf_ongoing, vf_new,
    common_time_model,
    k0_fit, t0_fit, t1_fit,
    ki_fit, ti_fit, di_fit,
    t0, t, ncores_max) {

  nreps = length(unique(vf_ongoing$draw))
  l = length(unique(vf_ongoing$kit))
  t1 = max(t)

  vf_kit <- vf_ongoing %>%
    select(-c("day", "dose")) %>%
    bind_rows(vf_new) %>%
    group_by(.data$draw, .data$usubjid, .data$kit, .data$kit_name) %>%
    slice(1) %>%
    select(c("draw", "usubjid", "kit", "kit_name"))

  # only keep the last record for each patient in each draw
  if (common_time_model) {
    vf_ongoing1 <- vf_ongoing %>%
      group_by(.data$draw, .data$usubjid) %>%
      slice(n()) %>%
      mutate(V = .data$day - 1,
             C = as.numeric(t0 - .data$arrivalTime),
             D = pmin(.data$time - 1, t1 - .data$arrivalTime)) %>%
      select(-c("kit", "kit_name", "day", "dose"))

    ### new patients and ongoing patients with no dosing records ###
    if (!is.null(vf_new)) {
      vf_new1 <- vf_new %>%
        group_by(.data$draw, .data$usubjid) %>%
        slice(n()) %>%
        mutate(V = 0,
               C = as.numeric(t0 - .data$arrivalTime),
               D = pmin(.data$time - 1, t1 - .data$arrivalTime)) %>%
        select(-c("kit", "kit_name"))
    } else {
      vf_new1 <- NULL
    }
  } else {
    vf_ongoing1 <- vf_ongoing %>%
      group_by(.data$kit, .data$kit_name, .data$draw, .data$usubjid) %>%
      slice(n()) %>%
      mutate(V = .data$day - 1,
             C = as.numeric(t0 - .data$arrivalTime),
             D = pmin(.data$time - 1, t1 - .data$arrivalTime)) %>%
      select(-c("day", "dose"))

    if (!is.null(vf_new)) {
      vf_new1 <- vf_new %>%
        mutate(V = 0,
               C = as.numeric(t0 - .data$arrivalTime),
               D = pmin(.data$time - 1, t1 - .data$arrivalTime))
    } else {
      vf_new1 <- NULL
    }
  }

  # first iteration to extract subject and summary data
  i = 1
  list1 <- f_dose_draw_1(
    i, common_time_model,
    k0_fit, t0_fit, t1_fit, ki_fit, ti_fit, di_fit,
    vf_ongoing, vf_ongoing1, vf_new, vf_new1,
    vf_kit, l, t)

  dosing_subject_new <- list1$dosing_subject_newi

  # register parallel backend
  ncores <- min(ncores_max, parallel::detectCores()/2)
  cl <- parallel::makeCluster(ncores)
  doParallel::registerDoParallel(cl)

  # subsequent iterations to extract summary data only
  dosing_summary_new <- foreach::foreach(
    i = 2:nreps, .combine = "bind_rows",
    .packages = c("dplyr", "mvtnorm")
  ) %dorng% {
    f_dose_draw_1(
      i, common_time_model,
      k0_fit, t0_fit, t1_fit, ki_fit, ti_fit, di_fit,
      vf_ongoing, vf_ongoing1, vf_new, vf_new1,
      vf_kit, l, t)$dosing_summary_newi
  }

  # shut down the cluster of workers
  parallel::stopCluster(cl)

  # combine the summary data from all iterations
  dosing_summary_new <- list1$dosing_summary_newi %>%
    bind_rows(dosing_summary_new)

  # output results for ongoing and new patients
  list(dosing_subject_new = dosing_subject_new,
       dosing_summary_new = dosing_summary_new)
}

