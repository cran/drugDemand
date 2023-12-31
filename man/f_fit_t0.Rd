% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/f_dispensing_models.R
\name{f_fit_t0}
\alias{f_fit_t0}
\title{Model Fitting for Dispensing Delay After Randomization}
\usage{
f_fit_t0(df, model, nreps, showplot = TRUE)
}
\arguments{
\item{df}{The subject-level dosing data, including the following
variables:
\itemize{
\item \code{time}: The number of days between randomization and the
first drug dispensing visit (first drug dispensing visit date -
randomization date + 1).
\item \code{left}: Equals \code{time - 1}, used to indicate the
left endpoint of an interval for interval censoring.
\item \code{right}: Equals \code{time}, used to indicate the
right endpoint of an interval for interval censoring.
}}

\item{model}{The event model used to analyze the gap time
between randomization and the first drug dispensing visit when
there is no visit skipping, with options including "constant",
"exponential", "weibull", "log-logistic", and "log-normal".}

\item{nreps}{The number of simulations for drawing posterior model
parameter values.}

\item{showplot}{A Boolean variable that controls whether or not to
show the fitted time-to-event bar chart. It defaults to \code{TRUE}.}
}
\value{
A list with three components:
\itemize{
\item \code{fit}: A list of results from the model fit that includes
\itemize{
\item \code{model}: The specific model used in the analysis.
\item \code{theta}: The estimated model parameters.
\item \code{vtheta}: The estimated covariance matrix of \code{theta}.
\item \code{aic}: The Akaike Information Criterion value.
\item \code{bic}: The Bayesian Information Criterion value.
}
\item \code{fit_plot}: A fitted time-to-event bar chart.
\item \code{theta}: Posterior draws of model parameters.
}
}
\description{
Fits a specified time-to-event model to the gap time
between randomization and the first drug dispensing visit when
there is no visit skipping.
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

vf <- vf \%>\%
  left_join(dosing_schedule_df, by = "drug")

vf1 <- vf \%>\%
  group_by(usubjid, day) \%>\%
  slice(n()) \%>\%
  group_by(usubjid) \%>\%
  mutate(row_id = row_number())

# time from randomization to the first drug dispensing visit
df_k0 <- vf1 \%>\%
  filter(row_id == 1) \%>\%
  mutate(time = day,
         skipped = floor((time - target_days/2)/target_days) + 1)

# no skipping
df_t0 <- df_k0 \%>\%
  filter(skipped == 0) \%>\%
  mutate(left = time - 1, right = time)

fit_t0 <- f_fit_t0(df_t0, model = "log-logistic", nreps = 200)

}
\author{
Kaifeng Lu, \email{kaifenglu@gmail.com}
}
