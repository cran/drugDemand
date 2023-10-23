% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/f_dose_pp.R
\name{f_cum_dose}
\alias{f_cum_dose}
\title{Cumulative Dose}
\usage{
f_cum_dose(x, w, d, N)
}
\arguments{
\item{x}{The treatment duration.}

\item{w}{The number of days per treatment cycle for the drug.}

\item{d}{The number of kits per treatment cycle for the drug.}

\item{N}{The maximum number of treatment cycles for the drug.}
}
\value{
The cumulative dose to dispense for the drug over a specified
treatment duration.
}
\description{
Obtains the cumulative dose given treatment duration and
dosing schedule.
}
\examples{

f_cum_dose(c(28, 70), 21, 2, 10000)

}
\author{
Kaifeng Lu, \email{kaifenglu@gmail.com}
}