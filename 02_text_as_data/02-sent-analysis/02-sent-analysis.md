---
title: "University of Edinburgh, Research Training Centre"
subtitle: "Computational Text Analysis (pt. 1)"
author:
  name: Christopher Barrie
  affiliation: University of Edinburgh | [AMWs](https://github.com/cjbarrie/ED-AMW)
output: 
  html_document:
    theme: flatly
    highlight: haddock
    # code_folding: show
    toc: yes
    toc_depth: 4
    toc_float: yes
    keep_md: true
    
bibliography: CTA.bib    
---


# Exercise 2: Sentiment analysis

The lecture mentioned work by @Lansdall-Welfare2017 and @Martins2020a. Both articles use different forms of sentiment analysis, constructing indices of different types. 

## Introduction

In this tutorial, you will learn how to:

* Use dictionary-based techniques to analyze text
* Use common sentiment dictionaries
* Apply more advanced sentiment analysis techniques, e.g., accounting for "valence shifters."
* Create your own dictionary

## Setup 

The hands-on exercise for this week uses dictionary-based methods for filtering and scoring words. Dictionary-based methods use pre-generated lexicons, which are no more than list of words with associated scores or variables measuring the valence of a particular word. In this sense, the exercise is not unlike our analysis of Edinburgh Book Festival event descriptions. Here, we were filtering descriptions based on the presence or absence of a word related to women or gender. We can understand this approach as a particularly simple type of "dictionary-based" method. Here, our "dictionary" or "lexicon" contained just a few words related to gender. 

In this exercise we'll be using another new dataset. The data were sourced from a series of webpages on the Internet Archive that host material collected at the Arab Spring protests in Egypt in 2011. The original website can be seen [here](https://www.tahrirdocuments.org/) and below.

![](images/tahrir_page.png){width=100%}

For full details of the technique used to scrape these webpages, see [here](https://raw.githack.com/cjbarrie/RDL-Ed/main/03-screenscrape-apis/03-week7.html).

##  Load data and packages 

Before proceeding, we'll load the remaining packages we will need for this tutorial.


```r
library(tidyverse) # loads dplyr, ggplot2, and others
library(readr) # more informative and easy way to import data
library(stringr) # to handle text elements
library(tidytext) # includes set of functions useful for manipulating text
```

We can download the final dataset with:


```r
pamphdata <- read_csv("data/pamphlets_formatted_gsheets.csv")
```

```
## Rows: 523 Columns: 8
```

```
## ?????? Column specification ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
## Delimiter: ","
## chr  (6): title, text, tags, imageurl, imgID, image
## dbl  (1): year
## date (1): date
```

```
## 
## ??? Use `spec()` to retrieve the full column specification for this data.
## ??? Specify the column types or set `show_col_types = FALSE` to quiet this message.
```

You can also view the formatted output of this scraping exercise, alongside images of the documents in question, in Google Sheets [here](https://docs.google.com/spreadsheets/d/1rg2VTV6uuknpu6u-L5n7kvQ2cQ6e6Js7IHp7CaSKe90/edit?usp=sharing).

If you're working on this document from your own computer ("locally") you can download the Tahrir documents data in the following way:


```r
pamphdata <- read_csv("https://raw.githubusercontent.com/cjbarrie/RDL-Ed/main/03-screenscrape-apis/data/pamphlets_formatted_gsheets.csv")
```

## Inspect and filter data 

Let's have a look at the data:


```r
head(pamphdata)
```

```
## # A tibble: 6 ?? 8
##   title      date        year text         tags      imageurl       imgID image 
##   <chr>      <date>     <dbl> <chr>        <chr>     <chr>          <chr> <chr> 
## 1 The Seaso??? 2011-03-30  2011 The Season ??? Solidari??? https://wayba??? imgI??? =Arra???
## 2 The Most ??? 2011-03-30  2011 [Voice of t??? Solidari??? https://wayba??? imgI??? <NA>  
## 3 Yes it???s ??? 2011-03-30  2011 [Voice of t??? Solidari??? https://wayba??? imgI??? <NA>  
## 4 The Revol??? 2011-03-30  2011 [Voice of t??? Revoluti??? https://wayba??? imgI??? <NA>  
## 5 Voice of ??? 2011-03-30  2011 February 18??? Revoluti??? https://wayba??? imgI??? <NA>  
## 6 We Are St??? 2011-03-29  2011 We Are Stil??? Demands,??? https://wayba??? imgI??? <NA>
```

Each document here is a pamphlet produced during the Arab Spring protests in Egypt in 2011. They have all been translated into English. The contents of each pamphlet are stored under the column entitled "text." This is the text with which we will be performing our analyses. Note also that each document has a particular date. We can therefore use these to look at any over time changes.

We manipulate the data into tidy format again, unnesting each token (here: words) from the pamphlet text. 


```r
tidy_pamph <- pamphdata %>% 
  mutate(desc = tolower(text)) %>%
  unnest_tokens(word, desc) %>%
  filter(str_detect(word, "[a-z]"))
```

We'll then tidy this further, as in the previous example, by removing stop words:


```r
tidy_pamph <- tidy_pamph %>%
    filter(!word %in% stop_words$word)
```

Then we can check what words we are left with that appear with most frequency in the cleaned data. We see that, as expected, we have lots of words relating to "revolution," "people," "demands" etc.:


```r
tidy_pamph %>%
  count(word, sort = TRUE)
```

```
## # A tibble: 12,133 ?? 2
##    word             n
##    <chr>        <int>
##  1 revolution    2051
##  2 people        1564
##  3 egypt         1073
##  4 egyptian      1049
##  5 al             905
##  6 regime         804
##  7 political      646
##  8 party          619
##  9 constitution   577
## 10 demands        575
## # ??? with 12,123 more rows
```

## Get sentiment dictionaries

Several sentiment dictionaries come bundled with the <tt>tidytext</tt> package. These are:

* `AFINN` from [Finn ??rup Nielsen](http://www2.imm.dtu.dk/pubdb/views/publication_details.php?id=6010),
* `bing` from [Bing Liu and collaborators](https://www.cs.uic.edu/~liub/FBS/sentiment-analysis.html), and
* `nrc` from [Saif Mohammad and Peter Turney](http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm)

We can have a look at some of these to see how the relevant dictionaries are stored. 


```r
get_sentiments("afinn")
```

```
## # A tibble: 2,477 ?? 2
##    word       value
##    <chr>      <dbl>
##  1 abandon       -2
##  2 abandoned     -2
##  3 abandons      -2
##  4 abducted      -2
##  5 abduction     -2
##  6 abductions    -2
##  7 abhor         -3
##  8 abhorred      -3
##  9 abhorrent     -3
## 10 abhors        -3
## # ??? with 2,467 more rows
```


```r
get_sentiments("bing")
```

```
## # A tibble: 6,786 ?? 2
##    word        sentiment
##    <chr>       <chr>    
##  1 2-faces     negative 
##  2 abnormal    negative 
##  3 abolish     negative 
##  4 abominable  negative 
##  5 abominably  negative 
##  6 abominate   negative 
##  7 abomination negative 
##  8 abort       negative 
##  9 aborted     negative 
## 10 aborts      negative 
## # ??? with 6,776 more rows
```


```r
get_sentiments("nrc")
```

```
## # A tibble: 13,901 ?? 2
##    word        sentiment
##    <chr>       <chr>    
##  1 abacus      trust    
##  2 abandon     fear     
##  3 abandon     negative 
##  4 abandon     sadness  
##  5 abandoned   anger    
##  6 abandoned   fear     
##  7 abandoned   negative 
##  8 abandoned   sadness  
##  9 abandonment anger    
## 10 abandonment fear     
## # ??? with 13,891 more rows
```

What do we see here. First, the `AFINN` lexicon gives words a score from -5 to +5, where more negative scores indicate more negative sentiment and more positive scores indicate more positive sentiment.  The `nrc` lexicon opts for a binary classification: positive, negative, anger, anticipation, disgust, fear, joy, sadness, surprise, and trust, with each word given a score of 1/0 for each of these sentiments. In other words, for the `nrc` lexicon, words appear multiple times if they enclose more than one such emotion (see, e.g., "abandon" above). The `bing` lexicon is most minimal, classifying words simply into binary "positive" or "negative" categories. 

Let's see how we might filter the texts by selecting a dictionary, or subset of a dictionary, and using `inner_join()` to then filter out pamphlet data. We might, for example, be interested in joy words. Maybe, we might hypothesize, there is a uptick of joy toward the beginning of the revolutionary uprising, which then subsequently declined. First, let's have a look at the words in our pamphlet data that the `nrc` lexicon codes as joy-related words.


```r
nrc_joy <- get_sentiments("nrc") %>% 
  filter(sentiment == "joy")

tidy_pamph %>%
  inner_join(nrc_joy) %>%
  count(word, sort = TRUE)
```

```
## Joining, by = "word"
```

```
## # A tibble: 336 ?? 2
##    word         n
##    <chr>    <int>
##  1 freedom    447
##  2 god        381
##  3 youth      285
##  4 ministry   180
##  5 money      159
##  6 true       135
##  7 achieve    114
##  8 victory    106
##  9 majority   104
## 10 wealth     103
## # ??? with 326 more rows
```


We have a total of 336 words with some joy valence in our pamphlet data according to the `nrc` classification. Several seem reasonable (e.g., "freedom," "victory"); others seems less so (e.g., "god," "ministry").

## Sentiment trends over time

Do we see any time trends? First let's make sure the data are properly arranged in ascending order by date. We'll then add column, which we'll call "order," the use of which will become clear when we do the sentiment analysis.


```r
#order and format date
tidy_pamph<- tidy_pamph %>%
  arrange(date)

tidy_pamph$order <- 1:nrow(tidy_pamph)
```

Remember that the structure of our pamphlet data is in a one token (word) per document (pamphlet) format. In order to look at sentiment trends over time, we'll need to decide over how many words to estimate the sentiment. 

In the below, we first add in our sentiment dictionary with `inner_join()`. We then use the `count()` function, specifying that we want to count over dates, and that words should be indexed in order (i.e., by row number) over every 1000 rows (i.e., every 1000 words). 

This means that if one date has many documents totalling >1000 words, then we will have multiple observations for that given date; if there are only one or two documents then we might have just one row and associated sentiment score for that date. 

We then calculate the sentiment scores for each of our sentiment types (positive, negative, anger, anticipation, disgust, fear, joy, sadness, surprise, and trust) and use the `spread()` function to convert these into separate columns (rather than rows). Finally we calculate a net sentiment score by subtracting the score for negative sentiment from positive sentiment. 


```r
#get tweet sentiment by date
pamph_nrc_sentiment <- tidy_pamph %>%
  inner_join(get_sentiments("nrc")) %>%
  count(date, index = order %/% 1000, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)
```

```
## Joining, by = "word"
```

```r
pamph_nrc_sentiment %>%
  ggplot(aes(date, sentiment)) +
  geom_point(alpha=0.5) +
  geom_smooth(method= loess, alpha=0.25)
```

```
## `geom_smooth()` using formula 'y ~ x'
```

![](02-sent-analysis_files/figure-html/unnamed-chunk-13-1.png)<!-- -->

How do our different sentiment dictionaries look when compared to each other? We can then plot the sentiment scores over time for each of our sentiment dictionaries like so:


```r
tidy_pamph %>%
  inner_join(get_sentiments("bing")) %>%
  count(date, index = order %/% 1000, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative) %>%
  ggplot(aes(date, sentiment)) +
  geom_point(alpha=0.5) +
  geom_smooth(method= loess, alpha=0.25) +
  ylab("bing sentiment")
```

```
## Joining, by = "word"
```

```
## `geom_smooth()` using formula 'y ~ x'
```

![](02-sent-analysis_files/figure-html/unnamed-chunk-14-1.png)<!-- -->

```r
tidy_pamph %>%
  inner_join(get_sentiments("nrc")) %>%
  count(date, index = order %/% 1000, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative) %>%
  ggplot(aes(date, sentiment)) +
  geom_point(alpha=0.5) +
  geom_smooth(method= loess, alpha=0.25) +
  ylab("nrc sentiment")
```

```
## Joining, by = "word"
## `geom_smooth()` using formula 'y ~ x'
```

![](02-sent-analysis_files/figure-html/unnamed-chunk-14-2.png)<!-- -->

```r
tidy_pamph %>%
  inner_join(get_sentiments("afinn")) %>%
  group_by(date, index = order %/% 1000) %>% 
  summarise(sentiment = sum(value)) %>% 
  ggplot(aes(date, sentiment)) +
  geom_point(alpha=0.5) +
  geom_smooth(method= loess, alpha=0.25) +
  ylab("afinn sentiment")
```

```
## Joining, by = "word"
```

```
## `summarise()` has grouped output by 'date'. You can override using the `.groups` argument.
```

```
## `geom_smooth()` using formula 'y ~ x'
```

![](02-sent-analysis_files/figure-html/unnamed-chunk-14-3.png)<!-- -->

We see that they do look pretty similar... but they're not particularly informative beyond telling us there's no obvious time trend. We might therefore choose to focus our attention on one particular sentiment. As noted above, we might hypothesize that there was a greater frequency of joy sentiment earlier on in the uprising. We can check this by simply changing the sentiment variable we're analyzing in the `nrc` dictionary:


```r
tidy_pamph %>%
  inner_join(get_sentiments("nrc")) %>%
  count(date, index = order %/% 1000, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  ggplot(aes(date, joy)) +
  geom_point(alpha=0.5) +
  geom_smooth(method= loess, alpha=0.25)
```

```
## Joining, by = "word"
```

```
## `geom_smooth()` using formula 'y ~ x'
```

![](02-sent-analysis_files/figure-html/unnamed-chunk-15-1.png)<!-- -->

We do some small evidence that there was a higher frequency of joy words earlier on in the uprising. Further analyses, however, might build a more domain-specific dictionary. For example, if we were interested in the frequency of democracy demands over time, we might build a specific lexicon for this, coding democracy-related words as 1 and everything else as 0.

## Exercises

1. Take a subset of the pamphlets data by "tag." These tags describe the content of the pamphlet. Do we see different sentiment dynamics if we look only at a subset of these documents?
2. Build your own (minimal) dictionary-based filter technique and plot the result

## References 
