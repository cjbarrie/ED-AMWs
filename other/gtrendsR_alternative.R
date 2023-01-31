library(gtrendsR)
library(ggplot2)
library(dplyr)

data("countries") # get abbreviations of all countries to filter data 
data("categories") # get numbers of all categories to filter data 

# Simple call

#find alternative gtrends() function to deal with 492 errors at:
# https://raw.githubusercontent.com/cjbarrie/ED-AMWs/main/other/gtrends_with_backoff.R

dat <- gtrends_with_backoff("racism",
               time = "2020-01-01 2020-08-22",
               geo = "GB",
               hl="en-US")


plot(dat)


remotes::install_github("trendecon/trendecon")
library(trendecon)
x <- ts_gtrends("cinema", geo = "CH")
#> Downloading data for today+5-y
tsbox::ts_plot(x)