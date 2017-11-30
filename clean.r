library(readr)
library(dplyr)
library(stringr)

# function for converting names to underscores
colnames_to_underscores <- function(colnames) {
    colnames <- colnames %>%
        # eliminate parens
        gsub('\\(\\)', '', .) %>%
        # other characters to underscores
        gsub('-|,|\\(|\\)', '_', .) %>% 
        # camelCase to underscore_case
        gsub('([a-z])([A-Z])', '\\1_\\L\\2', perl = TRUE, .) %>%  
        # eliminate duplicate underscores
        gsub('__', '_', .) 
    return(colnames)
}

# read the activity_link and the feature_link datasets
activity_link <- readr::read_delim(
    './data/UCI HAR Dataset/activity_labels.txt',
    delim = ' ',
    col_names = c("ActivityLabel", "ActivityName"))
feature_link <- readr::read_delim(
    './data/UCI HAR Dataset/features.txt',
    delim = ' ',
    col_names = c("FeatureLabel", "FeatureName"))


# join the ActivityLabel and ActivityName 
# there exist duplicate feature names, so we unite them with their ID
# no assumptions or corrections are made
feature_key <- stringr::str_c(
    feature_link$FeatureLabel, 
    feature_link$FeatureName,
    sep = ":")


# training dataframe
train_subject_tbl <- readr::read_table(
    './data/UCI HAR Dataset/train/subject_train.txt',
    col_names = c('SubjectLabel'))
train_x_tbl <- readr::read_table(
    './data/UCI HAR Dataset/train/X_train.txt',
    col_names = feature_key)

# get the activity data and link it to the names
train_y_tbl <- readr::read_table(
    './data/UCI HAR Dataset//train/y_train.txt',
    col_names = 'ActivityLabel') %>% 
        dplyr::right_join(activity_link, by = 'ActivityLabel')


# test dataframe
test_subject_tbl <- readr::read_table(
    './data/UCI HAR Dataset/test/subject_test.txt',
    col_names = c('SubjectLabel'))
test_x_tbl <- readr::read_table(
    './data/UCI HAR Dataset/test/X_test.txt',
    col_names = feature_key)

# get the activity data and link it to the names
test_y_tbl <- readr::read_table(
    './data/UCI HAR Dataset//test/y_test.txt',
    col_names = 'ActivityLabel') %>% 
        right_join(activity_link, by = 'ActivityLabel')


# assemble the sub-components of the complete table
complete_subject <- rbind(train_subject_tbl, test_subject_tbl)
complete_y <- rbind(train_y_tbl, test_y_tbl)
# add mean and sd for each row while assembling complete_x
complete_x <- rbind(train_x_tbl, test_x_tbl)
complete_x$obs_mean <- rowMeans(complete_x)
complete_x$obs_sd <- complete_x %>% dplyr::select(-obs_mean) %>% apply(1, sd)

# dplyr::select the proper columns for problem 5 before the conversion
task_5_tbl <- complete_x %>% dplyr::select(contains('std()'), contains('mean()'))

# convert the feature names to something more uniform
names(complete_x) <- colnames_to_underscores(names(complete_x))
names(task_5_tbl) <- colnames_to_underscores(names(task_5_tbl))

# stack all of the tables column-wise
complete_tbl <- cbind(complete_y, complete_subject, complete_x)

# write to file
readr::write_csv(complete_tbl, 'complete_tbl.csv')

# grouped analysis
task_6_tbl <- cbind(complete_subject, complete_y, task_5_tbl) %>%
    dplyr::select(-ActivityLabel) %>% 
    dplyr::group_by(SubjectLabel, ActivityName) %>% 
    dplyr::arrange(SubjectLabel, ActivityName) %>% 
    dplyr::summarise_all(funs(mean))

