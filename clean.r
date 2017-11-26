library(readr)
library(dplyr)
library(stringr)

# function for converting names to underscores
colnames_to_underscores <- function(colnames) {
    colnames <- colnames %>%
        gsub('\\(\\)', '', .) %>% # eliminate parens
        gsub('-|,|\\(|\\)', '_', .) %>% # other characters to underscores
        gsub('([a-z])([A-Z])', '\\1_\\L\\2', perl = T, .) %>%  # tBodyAcc -> t_body_acc
        gsub('__', '_', .) # eliminate duplicate underscores
    return(colnames)
}

# read the activity_link and the feature_link datasets
activity_link <- read_delim('./data/UCI HAR Dataset/activity_labels.txt',
                            delim = ' ', col_names = c("ActivityLabel", "ActivityName"))
feature_link <- read_delim('./data/UCI HAR Dataset/features.txt',
                           delim = ' ', col_names = c("FeatureLabel", "FeatureName"))


# join the ActivityLabel and ActivityName 
# there exist duplicate feature names, so we unite them with their ID
# no assumptions or corrections are made
feature_key <- str_c(feature_link$FeatureLabel, feature_link$FeatureName, sep = ":")


# training dataframe
train_subject_tbl <- read_table('./data/UCI HAR Dataset/train/subject_train.txt',
                                col_names = c('SubjectLabel'))
train_x_tbl <- read_table('./data/UCI HAR Dataset/train/X_train.txt',
                          col_names = feature_key)

# get the activity data and link it to the names
train_y_tbl <- read_table(
    './data/UCI HAR Dataset//train/y_train.txt', col_names = 'ActivityLabel') %>% 
        right_join(activity_link, by = 'ActivityLabel')


# test dataframe
test_subject_tbl <- read_table('./data/UCI HAR Dataset/test/subject_test.txt',
                        col_names = c('SubjectLabel'))
test_x_tbl <- read_table('./data/UCI HAR Dataset/test/X_test.txt',
                     col_names = feature_key)

# get the activity data and link it to the names
test_y_tbl <- read_table(
    './data/UCI HAR Dataset//test/y_test.txt', col_names = 'ActivityLabel') %>% 
        right_join(activity_link, by = 'ActivityLabel')


# assemble the sub-components of the final table
final_subject <- rbind(train_subject_tbl, test_subject_tbl)
final_y <- rbind(train_y_tbl, test_y_tbl)
# add mean and sd for each row while assembling final_x
final_x <- rbind(train_x_tbl, test_x_tbl)
final_x$obs_mean <- rowMeans(final_x)
final_x$obs_sd <- final_x %>% select(-obs_mean) %>% apply(1, sd)

# select the proper columns for problem 5 before the conversion
task_5_tbl <- final_x %>% select(contains('std()'), contains('mean()'))

# convert the feature names to something more uniform
names(final_x) <- colnames_to_underscores(names(final_x))
names(task_5_tbl) <- colnames_to_underscores(names(task_5_tbl))

# stack all of the tables column-wise
final_tbl <- cbind(final_y, final_subject, final_x)

# write to file
write_csv(final_tbl, 'final_tbl.csv')

# grouped analysis
task_6_tbl <- cbind(final_subject, final_y, task_5_tbl) %>%
    select(-ActivityLabel) %>% 
    group_by(SubjectLabel, ActivityName) %>% 
    arrange(SubjectLabel, ActivityName) %>% 
    summarise_all(funs(mean))

