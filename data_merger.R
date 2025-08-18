library(tidyverse)

# Read in the generated data
resultsFirstBatch <- read.csv("resultsFirstBatch.csv", stringsAsFactors = FALSE)
resultsSecondBatchA <- read.csv("resultsSecondBatchA.csv", stringsAsFactors = FALSE)
resultsSecondBatchB <- read.csv("resultsSecondBatchB.csv", stringsAsFactors = FALSE)
resultsThirdBatch <- read.csv("resultsThirdBatch.csv", stringsAsFactors = FALSE)

# Merge resultsSecondBatchA and resultsSecondBatchB, discarding duplicates where all columns except "result" are the same
resultsSecondBatch <- bind_rows(resultsSecondBatchA, resultsSecondBatchB) %>%
    distinct(across(-Response), .keep_all = TRUE)

# Combine all results into one dataframe
results <- bind_rows(resultsFirstBatch, resultsSecondBatch, resultsThirdBatch)

# Sort the table by Gender, Age, Kids, Politics, Education, Income, Inflation, Unemployment
results <- results %>%
    arrange(Gender, Age, Kids, Politics, Education, Income, Inflation, Unemployment)

# Wrtite the combined results to a new CSV file
write.csv(results, "results_complete.csv", row.names = FALSE)