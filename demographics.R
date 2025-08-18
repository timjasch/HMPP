# Clear workspace
rm(list = ls())

# Load libraries
library(tidyverse)
library(gridExtra)

# Using the CM Serif font, yes or no?
CM <- TRUE
# If CM = Yes, load the showtext library
if (CM == TRUE) {
    library(showtext)
    font_add(family = "CM",
        regular = "computer-modern/cmunrm.ttf",
        italic = "computer-modern/cmunsl.ttf"
    )
    showtext_auto()
}

# --- Load and preprocess data ---
results <- read.csv("Data/results_complete.csv", stringsAsFactors = FALSE)
results$Kids <- as.character(results$Kids)
results$Age <- as.character(results$Age)
results$Inflation <- as.numeric(results$Inflation)
results$Unemployment <- as.numeric(results$Unemployment)
results$Response <- as.numeric(results$Response)

# --- Regression analysis ---

# --- Small model without attributes ---
model_small <- lm(
    Response ~ Inflation + Unemployment,
    data = results
)
summary(model_small)

# --- Small model with interaction terms ---
model_small_interaction <- lm(
        Response ~ Inflation + Unemployment + Inflation:Unemployment + I(Inflation^2) + I(Unemployment^2),
        data = results
)
summary(model_small_interaction)

# --- Full model with all attributes ---
model_large <- lm(
    Response ~ Inflation + Unemployment + Gender + factor(Age) + factor(Kids) + Politics + Education + Income,
    data = results
)
summary(model_large)

# --- Full model with interaction terms for Gender and Politics ---
model_interaction_interactions <- lm(
        Response ~ Inflation + Unemployment + Gender + factor(Age) + factor(Kids) + Politics + Education + Income + Politics * Unemployment + Politics * Inflation + Gender * Unemployment + Gender * Inflation,
        data = results
)
summary(model_interaction_interactions)

#### Function to create heatmaps for demographics ####

# --- Function to create mean response data for a subgroup or overall ---
get_mean_response <- function(results, group_var = NULL) {
        if (is.null(group_var)) {
                results %>%
                        group_by(Inflation, Unemployment) %>%
                        summarise(Response = mean(Response, na.rm = TRUE), .groups = 'drop')
        } else {
                results %>%
                        group_by(.data[[group_var]], Inflation, Unemployment) %>%
                        summarise(Response = mean(Response, na.rm = TRUE), .groups = 'drop')
        }
}

# --- Function to fit smoothed Taylor rule model for a subgroup or overall ---
fit_taylor_smooth <- function(results, group_var = NULL, group_value = NULL) {
        if (is.null(group_var)) {
                subset <- results
        } else {
                subset <- results %>% filter(.data[[group_var]] == group_value)
        }
        if (nrow(subset) < 5) return(NULL)
        lm(Response ~ Inflation + Unemployment + Unemployment * Inflation, data = subset)
}

# --- Function to create a heatmap from data with fixed color scale ---
plot_heatmap <- function(data, title = "Heatmap", min_response = NULL, max_response = NULL) {
        if (is.null(min_response)) min_response <- min(data$Response, na.rm = TRUE)
        if (is.null(max_response)) max_response <- max(data$Response, na.rm = TRUE)
        ggplot(data, aes(x = Unemployment, y = Inflation, fill = Response)) +
                geom_tile() +
                scale_fill_gradientn(
                        colours = c("#ffffff", "#b3cde3", "#6497b1", "#005b96", "#03396c", "#011f4b", "#000000"),
                        values = scales::rescale(c(min_response, max_response)),
                        guide = "colorbar"
                ) +
                labs(title = title,
                         x = "Unemployment Rate",
                         y = "Inflation Rate",
                         fill = "Interest Rate Response") +
                theme_minimal() +
                coord_fixed(ratio = 1)
}

# --- Function to generate all plots for a given attribute with uniform color scale ---
model_attribute_heatmaps <- function(results, group_var = NULL) {
        if (is.null(group_var)) {
                # No grouping, just overall mean and model
                all_means <- get_mean_response(results)
                min_response <- min(all_means$Response, na.rm = TRUE)
                max_response <- max(all_means$Response, na.rm = TRUE)
                # Data (mean response) heatmap
                data_heatmap <- plot_heatmap(all_means, "Taylor Rule Data Heatmap", min_response, max_response)
                # Smooth (model-based) Taylor rule heatmap
                model <- fit_taylor_smooth(results)
                if (!is.null(model)) {
                        prediction_grid <- expand.grid(
                                Inflation = seq(0, 12, by = 0.1),
                                Unemployment = seq(0, 12, by = 0.1)
                        )
                        predictions <- predict(model, newdata = prediction_grid)
                        predicted <- cbind(prediction_grid, Response = predictions)
                        smooth_heatmap <- plot_heatmap(predicted, "Taylor Rule Smooth Heatmap", min_response, max_response)
                } else {
                        smooth_heatmap <- ggplot() + labs(title = "Insufficient data")
                }
                return(list(
                        Overall = list(
                                data_heatmap = data_heatmap,
                                smooth_heatmap = smooth_heatmap
                        )
                ))
        } else {
                categories <- unique(results[[group_var]])
                # Compute global min/max mean response for all categories
                all_means <- get_mean_response(results, group_var)
                min_response <- min(all_means$Response, na.rm = TRUE)
                max_response <- max(all_means$Response, na.rm = TRUE)
                plots <- list()
                for (cat in categories) {
                        # Data (mean response) heatmap
                        data_meaned <- all_means %>% filter(.data[[group_var]] == cat)
                        data_heatmap <- plot_heatmap(data_meaned, paste("Taylor Rule Data Heatmap \u2014", group_var, "=", cat), min_response, max_response)
                        # Smooth (model-based) Taylor rule heatmap
                        model <- fit_taylor_smooth(results, group_var, cat)
                        if (!is.null(model)) {
                                prediction_grid <- expand.grid(
                                        Inflation = seq(0, 12, by = 0.1),
                                        Unemployment = seq(0, 12, by = 0.1)
                                )
                                predictions <- predict(model, newdata = prediction_grid)
                                predicted <- cbind(prediction_grid, Response = predictions)
                                smooth_heatmap <- plot_heatmap(predicted, paste("Taylor Rule Smooth Heatmap \u2014", group_var, "=", cat), min_response, max_response)
                        } else {
                                smooth_heatmap <- ggplot() + labs(title = paste("Insufficient data for", cat))
                        }
                        plots[[cat]] <- list(
                                data_heatmap = data_heatmap,
                                smooth_heatmap = smooth_heatmap
                        )
                }
                return(plots)
        }
}

# --- Generate plots for each Attribute ---
attribute <- "All" # or "Education", "Gender", etc.
plots_by_category <- model_attribute_heatmaps(results)

# --- Arrange and display plots for all categories in a grid ---
# Apply CM font to all plots if CM == TRUE
if (CM == TRUE) {
        for (cat in names(plots_by_category)) {
                plots_by_category[[cat]]$data_heatmap <- plots_by_category[[cat]]$data_heatmap +
                        theme(text = element_text(family = "CM", size = 12))
                plots_by_category[[cat]]$smooth_heatmap <- plots_by_category[[cat]]$smooth_heatmap +
                        theme(text = element_text(family = "CM", size = 12))
        }
}

# Display data_heatmaps and smooth_heatmaps for each category, stacked vertically
plot_list <- c(
        lapply(names(plots_by_category), function(cat) {
                if (attribute == "All") {
                        plots_by_category[[cat]]$data_heatmap + ggtitle("Taylor Rule Data Heatmap")
                } else {
                        plots_by_category[[cat]]$data_heatmap + ggtitle(paste(attribute, "=", cat, "\u2014 Data"))
                }
        }),
        lapply(names(plots_by_category), function(cat) {
                if (attribute == "All") {
                        plots_by_category[[cat]]$smooth_heatmap + ggtitle("Taylor Rule Smooth Heatmap")
                } else {
                        plots_by_category[[cat]]$smooth_heatmap + ggtitle(paste(attribute, "=", cat, "\u2014 Smooth"))
                }
        })
)

# Arrange plots so that data heatmaps are in the left column and smooth heatmaps in the right column
# If attribute == "All", omit the attribute from the title
if (attribute == "All") {
    grid_title <- "Taylor Rule Data & Smooth Heatmaps"
} else {
    grid_title <- paste("Taylor Rule Data & Smooth Heatmaps by", attribute)
}

grid_overview <- grid.arrange(
    grobs = plot_list,
    ncol = 2,
    nrow = length(names(plots_by_category)),
    layout_matrix = cbind(
        seq_len(length(names(plots_by_category))),
        seq_len(length(names(plots_by_category))) + length(names(plots_by_category))
    ),
    top = grid_title
)

# Save each data_heatmap and smooth_heatmap individually for each category
for (cat in names(plots_by_category)) {
    # Save data heatmap
    ggsave(
        filename = paste0("Graphs/taylor_rule_heatmap_", attribute, "_", cat, "_data.pdf"),
        plot = plots_by_category[[cat]]$data_heatmap,
        width = 8,
        height = 8
    )
    # Save smooth heatmap
    ggsave(
        filename = paste0("Graphs/taylor_rule_heatmap_", attribute, "_", cat, "_smooth.pdf"),
        plot = plots_by_category[[cat]]$smooth_heatmap,
        width = 8,
        height = 8
    )
}