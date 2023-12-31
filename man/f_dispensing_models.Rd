% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/f_dispensing_models.R
\name{f_dispensing_models}
\alias{f_dispensing_models}
\title{Drug Dispensing Model Fitting}
\usage{
f_dispensing_models(
  vf,
  dosing_schedule_df,
  model_k0,
  model_t0,
  model_t1,
  model_ki,
  model_ti,
  model_di,
  nreps,
  showplot = TRUE
)
}
\arguments{
\item{vf}{A data frame for subject-level drug dispensing data,
including the following variables:
\code{drug}, \code{drug_name}, \code{dose_unit},
\code{usubjid}, \code{treatment}, \code{treatment_description},
\code{arrivalTime}, \code{time}, \code{event}, \code{dropout},
\code{day}, \code{dose}, \code{cum_dose}, and \code{row_id}.}

\item{dosing_schedule_df}{A data frame providing dosing schedule
information. It contains the following variables: \code{drug},
\code{target_days}, \code{target_dose}, and \code{max_cycles}.}

\item{model_k0}{The model for the number of skipped
visits between randomization and the first drug dispensing visit.
Options include "constant", "poisson", "zero-inflated poisson",
and "negative binomial".}

\item{model_t0}{The model for the gap time between randomization
and the first drug dispensing visit when there is no visit skipping.
Options include "constant", "exponential", "weibull",
"log-logistic", and "log-normal".}

\item{model_t1}{The model for the gap time between randomization
and the first drug dispensing visit when there is visit skipping.
Options include "least squares", and "least absolute deviations".}

\item{model_ki}{The model for the number of skipped
visits between two consecutive drug dispensing visits.
Options include "constant", "poisson", "zero-inflated poisson",
and "negative binomial".}

\item{model_ti}{The model for the gap time between two consecutive
drug dispensing visits. Options include "least squares"
and "least absolute deviations".}

\item{model_di}{The model for the dispensed doses at drug
dispensing visits. Options include "constant",
"linear model", and "linear mixed-effects model".}

\item{nreps}{The number of simulations for drawing posterior model
parameters.}

\item{showplot}{A Boolean variable that controls whether or not to
show the model fit plot. It defaults to \code{TRUE}.}
}
\value{
A list with the following components:
\itemize{
\item \code{common_time_model}: A Boolean variable that indicates
whether a common time model is used for drug dispensing visits.
\item \code{fit_k0}: The model fit for the number of skipped
visits between randomization and the first drug dispensing visit.
\item \code{fit_t0}: The model fit for the gap time between
randomization and the first drug dispensing visit when there is
no visit skipping.
\item \code{fit_t1}: The model fit for the gap time between
randomization and the first drug dispensing visit when there is
visit skipping.
\item \code{fit_ki}: The model fit for the number of skipped
visits between two consecutive drug dispensing visits.
\item \code{fit_ti}: The model fit for the gap time between two
consecutive drug dispensing visits.
\item \code{fit_di}: The model fit for the dispensed doses at drug
dispensing visits.
}
}
\description{
Fits drug dispensing models to the observed drug
dispensing data.
}
\examples{
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

dispensing_models <- f_dispensing_models(
  vf, dosing_schedule_df,
  model_k0 = "zero-inflated poisson",
  model_t0 = "log-logistic", model_t1 = "least squares",
  model_ki = "zero-inflated poisson", model_ti = "least squares",
  model_di = "linear mixed-effects model",
  nreps = 200, showplot = FALSE)

dispensing_models$fit_ki$fit_plot
}
\seealso{
\code{\link{f_fit_t0}}, \code{\link{f_fit_ki}},
\code{\link{f_fit_ti}}, \code{\link{f_fit_di}}
}
\author{
Kaifeng Lu, \email{kaifenglu@gmail.com}
}
