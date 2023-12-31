% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/f_dose_draw.R
\name{f_dose_draw_t_1}
\alias{f_dose_draw_t_1}
\title{Drug Dispensing Visit Dates Simulation for One Iteration}
\usage{
f_dose_draw_t_1(
  i,
  fit_k0,
  fit_t0,
  fit_t1,
  fit_ki,
  fit_ti,
  vf_ongoing1,
  vf_new1
)
}
\arguments{
\item{i}{The iteration number.}

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

\item{vf_ongoing1}{A data frame for the last observed drug dispensing
date for ongoing patients with drug dispensing records, with or without
the associated drug information. For the common time model, it includes
the following variables: \code{draw}, \code{usubjid},
\code{arrivalTime}, \code{treatment}, \code{treatment_description},
\code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.
For separate time models, it includes the following variables:
\code{draw}, \code{drug}, \code{drug_name}, \code{dose_unit},
\code{usubjid}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, \code{totalTime},
\code{V}, \code{C}, and \code{D}.}

\item{vf_new1}{A data frame for the randomization date for new patients
and ongoing patients with no drug dispensing records, with or without the
associated drug information. For the common time model, it includes
the following variables: \code{draw}, \code{usubjid},
\code{arrivalTime}, \code{treatment}, \code{treatment_description},
\code{time}, \code{totalTime}, \code{V}, \code{C}, and \code{D}.
For separate time models, it includes the following variables:
\code{draw}, \code{drug}, \code{drug_name}, \code{dose_unit},
\code{usubjid}, \code{arrivalTime}, \code{treatment},
\code{treatment_description}, \code{time}, \code{totalTime},
\code{V}, \code{C}, and \code{D}.}
}
\value{
A data frame containing the simulated drug dispensing visit
dates at the subject level for ongoing and new subjects. It includes
the following variables: \code{usubjid}, \code{day}, \code{draw},
\code{arrivalTime}, \code{treatment}, \code{treatment_description},
\code{time}, \code{totalTime}, and \code{status}.
}
\description{
Simulates drug dispensing visit dates for one iteration.
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
  model_k0 = "zero-inflated poisson",
  model_t0 = "log-logistic", model_t1 = "least squares",
  model_ki = "zero-inflated poisson", model_ti = "least squares",
  model_di = "linear mixed-effects model",
  nreps = 200, showplot = FALSE)

trialsdt = df$trialsdt[1]
cutoffdt = df$cutoffdt[1]
t0 = as.numeric(cutoffdt - trialsdt + 1)
nyears = 3
t1 = t0 + nyears*365
t = c(seq(t0, t1, 30), t1)

nreps = length(unique(newEvents$draw))
l = length(unique(treatment_by_drug_df$drug))

### dosing data for ongoing patients ###
vf1 <- vf \%>\%
  filter(event == 0) \%>\%
  select(drug, drug_name, dose_unit, usubjid, day, dose)

# ongoing subjects with dosing records
unames <- unique(vf1$usubjid)

# replicate nreps times
vf1_rep = tibble(draw = 1:nreps) \%>\%
  cross_join(vf1)

df1 <- newEvents \%>\%
  filter(usubjid \%in\% unames) \%>\%
  select(-c(event, dropout))

vf_ongoing <- vf1_rep \%>\%
  inner_join(df1, by = c("draw", "usubjid"))

### new patients and ongoing patients with no dosing records ###
df_new <- newEvents \%>\%
  filter(!(usubjid \%in\% unames))

vf_new <- purrr::map_dfr(
  1:l, function(h) {
    df_new \%>\%
      inner_join(treatment_by_drug_df \%>\% filter(drug == h),
                 by = "treatment")
  }) \%>\% select(-c(event, dropout))

# only keep the last record for each patient in each draw
vf_ongoing1 <- vf_ongoing \%>\%
  group_by(draw, usubjid) \%>\%
  slice(n()) \%>\%
  mutate(V = day - 1,
         C = as.numeric(t0 - arrivalTime),
         D = pmin(time - 1, t1 - arrivalTime)) \%>\%
  select(-c(drug, drug_name, dose_unit, day, dose))

### new patients and ongoing patients with no dosing records ###
vf_new1 <- vf_new \%>\%
  group_by(draw, usubjid) \%>\%
  slice(n()) \%>\%
  mutate(V = 0,
         C = as.numeric(t0 - arrivalTime),
         D = pmin(time - 1, t1 - arrivalTime)) \%>\%
  select(-c(drug, drug_name, dose_unit))

dosing_subject_new1 <- f_dose_draw_t_1(
  1, fit$fit_k0, fit$fit_t0, fit$fit_t1,
  fit$fit_ki, fit$fit_ti,
  vf_ongoing1, vf_new1)

head(dosing_subject_new1)
}

}
\seealso{
\code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
\code{\link{f_fit_ti}}
}
\author{
Kaifeng Lu, \email{kaifenglu@gmail.com}
}
