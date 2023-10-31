% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/f_dose_draw.R
\name{f_dose_draw}
\alias{f_dose_draw}
\title{Drug Dispensing Data Simulation}
\usage{
f_dose_draw(
  df,
  vf,
  newEvents,
  treatment_by_drug_df,
  common_time_model,
  fit_k0,
  fit_t0,
  fit_t1,
  fit_ki,
  fit_ti,
  fit_di,
  t0,
  t,
  ncores_max
)
}
\arguments{
\item{df}{A data frame for subject-level enrollment and event data,
including the following variables:
\code{trialsdt}, \code{usubjid}, \code{randdt},
\code{treatment}, \code{treatment_description},
\code{time}, \code{event}, \code{dropout}, and \code{cutoffdt}.}

\item{vf}{A data frame for subject-level drug dispensing data,
including the following variables:
\code{drug}, \code{drug_name}, \code{dose_unit},
\code{usubjid}, \code{treatment}, \code{treatment_description},
\code{arrivalTime}, \code{time}, \code{event}, \code{dropout},
\code{day}, \code{dose}, \code{cum_dose}, and \code{row_id}.}

\item{newEvents}{A data frame containing the imputed event data
for both ongoing and new patients, typically obtained from
the output of the \code{eventPred::getPrediction} function.
It contains the following variables:
\code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, \code{event},
\code{dropout}, and \code{totalTime}.}

\item{treatment_by_drug_df}{A data frame indicating the treatments
associated with each drug, including the following variables:
\code{treatment}, \code{drug}, \code{drug_name}, and
\code{dose_unit}.}

\item{common_time_model}{A Boolean variable that indicates whether
a common time model is used for drug dispensing visits.}

\item{fit_k0}{The model fit for the number of skipped
visits between randomization and the first drug dispensing visit.}

\item{fit_t0}{The model fit for the gap time between randomization
and the first drug dispensing visit when there is no visit skipping.}

\item{fit_t1}{The model fit for the gap time between randomization
and the first drug dispensing visit when there is visit skipping.}

\item{fit_ki}{The model fit for the number of skipped
visits between two consecutive drug dispensing visits.}

\item{fit_ti}{The model fit for the gap time between two
consecutive drug dispensing visits.}

\item{fit_di}{The model fit for the dispensed doses at drug
dispensing visits.}

\item{t0}{The cutoff date relative to the trial start date.}

\item{t}{A vector of new time points for drug dispensing prediction.}

\item{ncores_max}{The maximum number of cores to use for parallel
computing. The actual number of cores used is the minimum of
\code{ncores_max} and half of the detected number of cores.}
}
\value{
A list with two components:
\itemize{
\item \code{dosing_subject_new}: A data frame containing observed and
imputed subject-level dosing records for ongoing and new patients
for the first iteration. It contains the following variables:
\code{draw}, \code{drug}, \code{drug_name}, \code{dose_unit},
\code{usubjid}, \code{day}, \code{dose}, \code{arrivalTime},
\code{treatment}, \code{treatment_description}, \code{time},
and \code{totalTime}.
\item \code{dosing_summary_new}: A data frame providing dosing summaries
by drug, future time point, and simulation draw for ongoing
and new patients. It contains the following variables:
\code{drug}, \code{drug_name}, \code{dose_unit}, \code{t},
\code{draw}, and \code{total_dose_b}.
}
}
\description{
Simulates drug dispensing data after cutoff for
both ongoing and new patients.
}
\examples{

\donttest{
set.seed(431)
library(dplyr)

df <- df2 \%>\%
  mutate(arrivalTime = as.numeric(randdt - trialsdt + 1))

vf <- visitview2 \%>\%
  inner_join(df, by = "usubjid") \%>\%
  mutate(day = as.numeric(date - randdt + 1)) \%>\%
  select(drug, drug_name, dose_unit, usubjid, treatment,
         treatment_description, arrivalTime,
         time, event, dropout, day, dispensed_quantity) \%>\%
  group_by(drug, drug_name, dose_unit, usubjid, treatment,
           treatment_description, arrivalTime,
           time, event, dropout, day) \%>\%
  summarise(dose = sum(dispensed_quantity), .groups = "drop_last") \%>\%
  mutate(cum_dose = cumsum(dose)) \%>\%
  group_by(drug, drug_name, dose_unit, usubjid) \%>\%
  mutate(row_id = row_number())

pred <- eventPred::getPrediction(
  df = df,
  to_predict = "event only",
  target_d = 250,
  event_model = "log-logistic",
  dropout_model = "none",
  pilevel = 0.95,
  nyears = 3,
  nreps = 200,
  showsummary = FALSE,
  showplot = FALSE,
  by_treatment = TRUE)
newEvents <- pred$event_pred$newEvents

treatment_by_drug_df <- vf \%>\%
  group_by(treatment, drug, drug_name, dose_unit) \%>\%
  slice(n()) \%>\%
  select(treatment, drug, drug_name, dose_unit)

fit <- f_dispensing_models(
  vf, dosing_schedule_df,
  model_k0 = "zip", model_t0 = "log-logistic",
  model_ki = "zip", model_di = "lme",
  nreps = 200, showplot = FALSE)

trialsdt = df$trialsdt[1]
cutoffdt = df$cutoffdt[1]
t0 = as.numeric(cutoffdt - trialsdt + 1)
nyears = 3
t1 = t0 + nyears*365
t = c(seq(t0, t1, 30), t1)

dose_draw <- f_dose_draw(
  df, vf, newEvents, treatment_by_drug_df,
  fit$common_time_model,
  fit$fit_k0, fit$fit_t0, fit$fit_t1,
  fit$fit_ki, fit$fit_ti, fit$fit_di,
  t0, t, ncores_max = 2)

head(dose_draw$dosing_subject_new)
head(dose_draw$dosing_summary_new)
}

}
\seealso{
\code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
\code{\link{f_fit_ti}}, \code{\link{f_fit_di}}
}
\author{
Kaifeng Lu, \email{kaifenglu@gmail.com}
}