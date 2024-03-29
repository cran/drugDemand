% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/f_dose_draw.R
\name{f_dose_draw_1}
\alias{f_dose_draw_1}
\title{Drug Dispensing Data Simulation for One Iteration}
\usage{
f_dose_draw_1(
  i,
  common_time_model,
  k0_fit,
  t0_fit,
  t1_fit,
  ki_fit,
  ti_fit,
  di_fit,
  vf_ongoing,
  vf_ongoing1,
  vf_new,
  vf_new1,
  vf_kit,
  l,
  t
)
}
\arguments{
\item{i}{The iteration number.}

\item{common_time_model}{A Boolean variable that indicates whether
a common time model is used for drug dispensing visits.}

\item{k0_fit}{The model fit for the number of skipped
visits between randomization and the first drug dispensing visit.}

\item{t0_fit}{The model fit for the gap time between randomization
and the first drug dispensing visit when there is no visit skipping.}

\item{t1_fit}{The model fit for the gap time between randomization
and the first drug dispensing visit when there is visit skipping.}

\item{ki_fit}{The model fit for the number of skipped
visits between two consecutive drug dispensing visits.}

\item{ti_fit}{The model fit for the gap time between two
consecutive drug dispensing visits.}

\item{di_fit}{The model fit for the dispensed doses at drug
dispensing visits.}

\item{vf_ongoing}{A data frame for the observed drug dispensing
data for ongoing patients with drug dispensing records.
It includes the following variables:
\code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
\code{day}, \code{dose}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, and \code{totalTime}.}

\item{vf_ongoing1}{A data frame for the last observed drug dispensing
date for ongoing patients with drug dispensing records.
For the common time model, it includes the following variables:
\code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, \code{totalTime},
\code{V}, \code{C}, and \code{D}.
For separate time models, it includes the following variables:
\code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
\code{arrivalTime}, \code{treatment}, \code{treatment_description},
\code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.}

\item{vf_new}{A data frame for the randomization date for new
patients and ongoing patients with no drug dispensing records.
It includes the following variables:
\code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
\code{arrivalTime}, \code{treatment}, \code{treatment_description},
\code{time}, and \code{totalTime}.}

\item{vf_new1}{A data frame for the randomization date for new patients
and ongoing patients with no drug dispensing records.
For the common time model, it includes the following variables:
\code{draw}, \code{usubjid}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, \code{totalTime},
\code{V}, \code{C}, and \code{D}.
For separate time models, it includes the following variables:
\code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
\code{arrivalTime}, \code{treatment}, \code{treatment_description},
\code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.}

\item{vf_kit}{A data frame indicating the kit names for each subject
by draw. It includes the following variables:
\code{draw}, \code{usubjid}, \code{kit}, and \code{kit_name}.}

\item{l}{Number of kit types.}

\item{t}{A vector of new time points for drug dispensing prediction.}
}
\value{
A list of two components:
\itemize{
\item \code{dosing_subject_newi}: A data frame for the drug dispensing
data at the subject level by date for ongoing and new subjects
for the given iteration. It contains the following variables:
\code{draw}, \code{kit}, \code{kit_name}, \code{usubjid},
\code{day}, \code{dose}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, and \code{totalTime}.
\item \code{dosing_summary_newi}: A data frame for the drug dispensing
summary data by drug, time, and simulation draw for ongoing and
new subjects for the given iteration. It includes the following
variables:
\code{kit}, \code{kit_name}, \code{t}, \code{draw}, and
\code{total_dose_b}.
}
}
\description{
Simulates drug dispensing data for one iteration.
}
\examples{

\donttest{
set.seed(431)
library(dplyr)

pred <- eventPred::getPrediction(
  df = df2,
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

observed <- f_dose_observed(df2, visitview2, showplot = FALSE)

fit <- f_dispensing_models(
  observed$vf, dosing_schedule_df,
  model_k0 = "zero-inflated poisson",
  model_t0 = "log-logistic",
  model_t1 = "least squares",
  model_ki = "zero-inflated poisson",
  model_ti = "least squares",
  model_di = "linear mixed-effects model",
  nreps = 200, showplot = FALSE)

trialsdt = df2$trialsdt[1]
cutoffdt = df2$cutoffdt[1]
t0 = as.numeric(cutoffdt - trialsdt + 1)
nyears = 3
t1 = t0 + nyears*365
t = c(seq(t0, t1, 30), t1)

l = nrow(observed$kit_description_df)

vf_ongoing_new <- f_ongoing_new(
  pred$event_pred$newEvents,
  observed$kit_description_df,
  observed$treatment_by_drug_df,
  observed$vf)

vf_ongoing <- vf_ongoing_new$vf_ongoing
vf_new <- vf_ongoing_new$vf_new

vf_kit <- vf_ongoing \%>\%
  select(-c("day", "dose")) \%>\%
  bind_rows(vf_new) \%>\%
  group_by(draw, usubjid, kit, kit_name) \%>\%
  slice(1) \%>\%
  select(c("draw", "usubjid", "kit", "kit_name"))

vf_ongoing1 <- vf_ongoing \%>\%
  group_by(draw, usubjid) \%>\%
  slice(n()) \%>\%
  mutate(V = day - 1,
         C = as.numeric(t0 - arrivalTime),
         D = pmin(time - 1, t1 - arrivalTime)) \%>\%
  select(-c("kit", "kit_name", "day", "dose"))

### new patients and ongoing patients with no dosing records ###
vf_new1 <- vf_new \%>\%
  group_by(draw, usubjid) \%>\%
  slice(n()) \%>\%
  mutate(V = 0,
         C = as.numeric(t0 - arrivalTime),
         D = pmin(time - 1, t1 - arrivalTime)) \%>\%
  select(-c("kit", "kit_name"))

# first iteration to extract subject and summary data
list1 <- f_dose_draw_1(
  1, fit$common_time_model,
  fit$k0_fit, fit$t0_fit, fit$t1_fit,
  fit$ki_fit, fit$ti_fit, fit$di_fit,
  vf_ongoing, vf_ongoing1, vf_new, vf_new1,
  vf_kit, l, t)

head(list1$dosing_subject_newi)
head(list1$dosing_summary_newi)
}

}
\seealso{
\code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
\code{\link{f_fit_ti}}, \code{\link{f_fit_di}}
}
\author{
Kaifeng Lu, \email{kaifenglu@gmail.com}
}
