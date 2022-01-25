library(readr)
library(stringr)
library(tidytext)
library(dplyr)

pamphdata <- read_csv("https://raw.githubusercontent.com/cjbarrie/RDL-Ed/main/03-screenscrape-apis/data/pamphlets_formatted_gsheets.csv")

pamphdata$tags <- tolower(pamphdata$tags)

pamphdata$culture_tag <- as.integer(grepl("culture", 
                                             x = pamphdata$tags))

pamph_culture <- pamphdata %>%
  dplyr::filter(culture_tag==1)

#OR

pamph_culture <- pamphdata %>%
  filter(str_detect(pamphdata$tags, "culture"))

tidy_pamph <- pamphdata %>% 
  mutate(desc = tolower(text)) %>%
  unnest_tokens(word, desc) %>%
  filter(str_detect(word, "[a-z]"))

tidy_pamph <- tidy_pamph %>%
  filter(!word %in% stop_words$word)


#order and format date
tidy_pamph<- tidy_pamph %>%
  arrange(date)

tidy_pamph$order <- 1:nrow(tidy_pamph)


#get tweet sentiment by date
pamph_nrc_sentiment <- tidy_pamph %>%
  inner_join(get_sentiments("nrc")) %>%
  count(date, index = order %/% 1000, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)