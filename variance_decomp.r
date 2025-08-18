# Clear workspace
rm(list = ls())

# Load libraries
library(tidyverse)
library(gridExtra)
library(waffle)

# --- Font setup (optional) ---
CM <- TRUE
if (CM) {
    library(showtext)
    font_add(family = "CM",
             regular = "computer-modern/cmunrm.ttf",
             italic = "computer-modern/cmunsl.ttf")
    showtext_auto()
}

# --- Load and preprocess data ---
results <- read.csv("Data/results_complete.csv", stringsAsFactors = FALSE) %>%
    mutate(
        Kids = as.character(Kids),
        Age = as.character(Age),
        Inflation = as.numeric(Inflation),
        Unemployment = as.numeric(Unemployment),
        Response = as.numeric(Response)
    )

# --- Model fitting ---
model_econ <- lm(Response ~ Inflation + Unemployment, data = results)
r2_econ <- summary(model_econ)$r.squared

model_full <- lm(Response ~ Inflation + Unemployment + Gender + factor(Age) +
                 factor(Kids) + Politics + Education + Income, data = results)
sr2_full <- summary(model_full)$r.squared

# --- Attribute-wise R^2 calculation ---
get_r2 <- function(attr) {
    f <- as.formula(paste("Response ~ Inflation + Unemployment +", attr))
    summary(lm(f, data = results))$r.squared
}
attributes <- c("Gender", "Age", "Kids", "Politics", "Education", "Income")
r2_attributes <- sapply(attributes, get_r2)

# --- Relative importance calculation ---
relative_importance <- c(Economics = r2_econ, r2_attributes - r2_econ)
relative_importance <- sort(relative_importance, decreasing = TRUE)

# --- Prepare data for plotting ---
explained <- sum(relative_importance)
importance_df <- data.frame(
    Attribute = names(relative_importance),
    Importance = relative_importance
) %>%
    add_row(Attribute = "Unexplained Variance", Importance = 1 - explained)

# --- Waffle plot ---
total_parts <- 100
importance_df$Parts <- round(importance_df$Importance / sum(importance_df$Importance) * total_parts)

custom_colors <- c(
    "Economics" = "#1f77b4",
    "Gender" = "#a72dd3",
    "Age" = "#db5c5c",
    "Kids" = "#778372",
    "Politics" = "#66a61e",
    "Education" = "#e6ab02",
    "Income" = "#373737",
    "Unexplained Variance" = "#cccccc"
)

decomposition <- waffle(
    parts = setNames(importance_df$Parts, importance_df$Attribute),
    rows = 5,
    colors = custom_colors#,
    #title = "Variance Decomposition of the Interest Response"
)

if (CM) {
    decomposition <- decomposition +
        theme(text = element_text(family = "CM", size = 12))
}

# --- Save plot ---
ggsave("Graphs/Variance_decomposition.pdf", width = 10, height = 3, plot = decomposition)
