---
title: "Tidying the UCI HAR Dataset"
author: "Alex Mitan"
date: "November 22, 2017"
output: html_document
---

# Overview of the dataset

--------------------------

The [UCI Human Activity Recognition dataset](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones) consists of accelerometer and gyroscope measurements performed as part of an experiment carried out with a group of 30 volunteers. Each person performed six activities (walking, standing, etc.) wearing a smartphone on the waist.

The dataset is partitioned into a training set and a test set, with a ratio of 70%:30% respectively, and each in turn separated over several sub-folders and label-to-index linking tables.

The result of the data cleaning operation is a single tidy dataset comprised of the labels appended explicitly before the numerical data, as well as other modifications and utilities listed below.

# Process description

## Libraries

---

Several packages from the `tidyverse` were used for brevity and performance:

- `readr` - reading the information from the files, primarily whitespace-separated tables
- `dplyr` - joining the numerically-labelled Y tables with their equivalent activity names
- `stringr` - joining the numerical label and the literal feature names in the X tables, because of duplicate feature names

## Steps

---

The process of tidying the data was as follows:

1. Load the appropriate libraries.
1. Read the **activity_link** and the **feature_link** datasets.
1. Join the `ActivityLabel` and `ActivityName` data in **activity_link** to provide a predictable way to handle `ActivityName` duplicates (detailed below).
1. Read the **train_subject** table, which details which subject performed which measurements.
1. Read the **train_x table**, which provides the raw data, consisting of values within [-1, 1].
1. Read the **train_y table**, providing the labels of the activities performed, and immediately join it with the unique feature keys from **activity_link's** columns.
1. Perform steps 4-6 for the testing dataset analogously.
1. Assemble the sub-components of the final table (Y, subject data, feature values)
1. Append a **mean** and **sd** column to **final_x** for analysis of each row.
1. Select the columns for the **task_5_tbl** before converting feature names, as the pattern is more apparent initially.
1. Convert the feature names to lowercase, underscore notation.
1. Bind the sub-components column-wise into **final_tbl**,
1. Store the **final** table into a *.tsv* file, since commas are present in the column names. Data is preserved, as tested in the `sanity_checks.r` file.
1. Create and plot the **mean_all** and **sd_all** datasets analysing the columns of **final_x**.
1. Use the **task_5_tbl**, with subject and activity names added, to do a short analysis (group by subject and activity, calculate the mean of each feature).
## Structure

---

The final dataframe has the following attributes:

- `SubjectLabel` - an integer from 1 to 30, labelling the human volunteer carrying the sensors
- `ActivityLabel` - an integer from 1 to 6, labelling the activity undertaken (such as walking, laying down). *The effective Y label*
- `ActivityName` - uppercase string, the name of the activity, found in a one-to-one mapping in `activity_link`
- **561 other columns** - floats in the interval [-1, 1] describing various sensor readings of velocity and rotation, normalised to the interval

In total, there are **10,299 observations** of **564 variables**.

## Sanity Checks

---

Over the duration of the process, I have put together a file that checks the integrity of the process, as well as including some oddities and observations:


- Feature name duplicate analysis

```R
mean(duplicated(feature_link$FeatureName))    # 14.9% are duplicates
sum(duplicated(feature_link$FeatureName)) / 2 # 42 duplicates

# demonstration of duplicates
duped <- 'fBodyAcc-bandsEnergy()-1,16'
# get duplicated_ids
feature_link %>%
    filter(FeatureName == duped) %>%
    .[['FeatureLabel']]
# 311 325 339 - duplicate indexes
```

- Checking that data is preserved

```R
recovered_tbl <- read_csv('final_tbl.csv')
all(names(recovered_tbl) == names(final_tbl)) # TRUE
all_equal(recovered_tbl, final_tbl) # TRUE
```

- Small-scale test of the analysis of task 6

```R
mini <- final_tbl[1:5*100, 1:5]
mini %>%
    group_by(SubjectLabel, ActivityName) %>% 
    summarise_all(funs(mean)) %>% 
    arrange(SubjectLabel, ActivityName)
```

- Interesting patterns in the processed data

```R
plot(feature_means$obs_mean, feature_means$obs_sd)
```

- Miscellaneous

```R
# No missing values
all(complete.cases(final_tbl))

# No values outside of [-1, 1]
all(test_x_tbl >= -1 & test_x_tbl <= 1)

# "LAYING" seems to be the most commonly measured activity
final_tbl %>% group_by(ActivityName) %>% summarise(count=n())
```

## Oddities / Difficulties

---

Applying the sd and mean of each row with a different function(`rowMeans` vs `apply, sd`) feels inconsistent, and mentioning the frame's name inside the mutation feels wrong. I've heard of `rowwise()` but I'm not completely sure how it could help me here more than what I did. Do I need to provide it with all of the column names, stored as a vector?

I have knowingly converted the feature names to *underscore_lowercase*, despite the inconsistency with `ActivityName` and `ActivityLabel` as a demonstration while keeping the assignment's literal request in mind. Normally I would keep the same notation, and prefer underscores for all.

There was always the option of doing the entire process in R Markdown, avoiding the "duplication" of code between the cleaning script, the sanity-checks and the report. It might have documented and assisted the process in real time, but I was unsure whether a semi-intensive data processing task is suitable for a live, dynamically-generated markdown report. The sanity checks could have benefitted from real-time rmd. I need further clarification regarding what is and isn't "Rmd material" and what should stay in a plain R script.