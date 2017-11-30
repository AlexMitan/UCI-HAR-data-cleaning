# no missing values
all(complete.cases(complete_tbl)) # TRUE

# check for erroneous values
all(test_x_tbl >= -1 & test_x_tbl <= 1) # TRUE

# check for duplicates
nrow(distinct(complete_tbl)) == nrow(complete_tbl) # TRUE

# check distribution of activities, walking is the most common
complete_tbl %>% group_by(ActivityName) %>% summarise(count=n())

# check for duplicate feature names
mean(duplicated(feature_link$FeatureName))    # 14.9% are duplicates
sum(duplicated(feature_link$FeatureName)) / 2 # 42 duplicates

# demonstration of duplicates
duped <- 'fBodyAcc-bandsEnergy()-1,16'
# get duplicated_ids
feature_link %>%
    filter(FeatureName == duped) %>%
    .[['FeatureLabel']]
# 311 325 339 - duplicate indexes

# checking preservation of data
recovered_tbl <- read_csv('complete_tbl.csv')
all(names(recovered_tbl) == names(complete_tbl)) # TRUE
all_equal(recovered_tbl, complete_tbl) # TRUE

# # interesting pattern, two obvious clusters
# plot(feature_means$obs_mean, feature_means$obs_sd)

# small-scale verification of the group analysis
mini <- complete_tbl[1:5*100, 1:5]
mini %>%
    group_by(SubjectLabel, ActivityName) %>% 
    summarise_all(funs(mean)) %>% 
    arrange(SubjectLabel, ActivityName)

# some testing with the bands features
bands_tbl <- complete_tbl %>%
    select(ActivityName,contains('bands')) %>%
    group_by(ActivityName) %>%
    summarise_all(funs(mean))

