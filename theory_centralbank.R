# Clean the environment
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

#### Theoretical Taylor rule ####

# --- Theoretical Taylor rule ---
taylor_data <- expand.grid(
  Inflation = seq(0, 12, by = 0.1),
  Unemployment = seq(0, 12, by = 0.1)
) %>%
  # Weights based on the classical Taylor rule (1993)
  mutate(Response = 2 + 1.5 * (Inflation - 2) - 0.5 * (Unemployment - 4))

# --- Create heatmap for the theoretical Taylor rule ---
theory_heatmap <- ggplot(taylor_data, aes(x = Unemployment, y = Inflation, fill = Response)) +
  geom_tile() +
  scale_fill_gradientn(
    colours = c("#ffffff", "#b3cde3", "#6497b1", "#005b96", "#03396c", "#011f4b", "#000000"),
    values = scales::rescale(c(min(taylor_data$Response, na.rm = TRUE),
                               max(taylor_data$Response, na.rm = TRUE))),
    guide = "colorbar"
  ) +
  labs(title = "Theoretical Taylor Rule Heatmap",
       x = "Unemployment Rate",
       y = "Inflation Rate",
       fill = "Interest Rate Response") +
  theme_minimal() +
  coord_fixed(ratio = 1)

# Apply CM font if set to TRUE
if (CM == TRUE) {
    theory_heatmap <- theory_heatmap + theme(text = element_text(family = "CM", size = 12))
}

# Save the theoretical heatmap
ggsave("Graphs/theory_heatmap.pdf", plot = theory_heatmap, width = 8, height = 8)

##### Central Bank Results #####

# Reading in the central bank results
cb_restricted_results <- read.csv("Data/resultsCentralBank.csv", stringsAsFactors = FALSE)
cb_freeflow_results <- read.csv("Data/resultsCentralBankFREEFLOW.csv", stringsAsFactors = FALSE)
cb_hightemp_results <- read.csv("Data/resultsCentralBankHIGHTEMP.csv", stringsAsFactors = FALSE)

# Calculate mean response for each scenario in central bank results
central_bank_meaned <- cb_restricted_results %>%
  group_by(Inflation, Unemployment) %>%
  summarise(Response = mean(Response, na.rm = TRUE), .groups = 'drop')

# Plotting the central bank results heatmap for restricted scenario
central_bank_heatmap_restricted <- ggplot(
  cb_restricted_results %>%
    group_by(Inflation, Unemployment) %>%
    summarise(Response = mean(Response, na.rm = TRUE), .groups = 'drop'),
  aes(x = Unemployment, y = Inflation, fill = Response)
) +
  geom_tile() +
  scale_fill_gradientn(
    colours = c("#ffffff", "#b3cde3", "#6497b1", "#005b96", "#03396c", "#011f4b", "#000000"),
    values = scales::rescale(c(
      min(cb_restricted_results$Response, na.rm = TRUE),
      max(cb_restricted_results$Response, na.rm = TRUE)
    )),
    guide = "colorbar"
  ) +
  labs(title = "Central Bank Heatmap (Restricted)",
       x = "Unemployment Rate",
       y = "Inflation Rate",
       fill = "Interest Rate Response") +
  theme_minimal() +
  coord_fixed(ratio = 1)

# Plotting the central bank results heatmap for free flow scenario
central_bank_heatmap_freeflow <- ggplot(
  cb_freeflow_results %>%
    group_by(Inflation, Unemployment) %>%
    summarise(Response = mean(Interest.Rate, na.rm = TRUE), .groups = 'drop'),
  aes(x = Unemployment, y = Inflation, fill = Response)
) +
  geom_tile() +
  scale_fill_gradientn(
    colours = c("#ffffff", "#b3cde3", "#6497b1", "#005b96", "#03396c", "#011f4b", "#000000"),
    values = scales::rescale(c(
      min(cb_freeflow_results$Interest.Rate, na.rm = TRUE),
      max(cb_freeflow_results$Interest.Rate, na.rm = TRUE)
    )),
    guide = "colorbar"
  ) +
  labs(title = "Central Bank Heatmap (Free Flow)",
       x = "Unemployment Rate",
       y = "Inflation Rate",
       fill = "Interest Rate Response") +
  theme_minimal() +
  coord_fixed(ratio = 1)

# Plotting the central bank results heatmap for high temp scenario
central_bank_heatmap_hightemp <- ggplot(
  cb_hightemp_results %>%
    group_by(Inflation, Unemployment) %>%
    summarise(Response = mean(Interest.Rate, na.rm = TRUE), .groups = 'drop'),
  aes(x = Unemployment, y = Inflation, fill = Response)
) +
  geom_tile() +
  scale_fill_gradientn(
    colours = c("#ffffff", "#b3cde3", "#6497b1", "#005b96", "#03396c", "#011f4b", "#000000"),
    values = scales::rescale(c(
      min(cb_hightemp_results$Interest.Rate, na.rm = TRUE),
      max(cb_hightemp_results$Interest.Rate, na.rm = TRUE)
    )),
    guide = "colorbar"
  ) +
  labs(title = "Central Bank Heatmap (High Temp)",
       x = "Unemployment Rate",
       y = "Inflation Rate",
       fill = "Interest Rate Response") +
  theme_minimal() +
  coord_fixed(ratio = 1)

# --- Calculate conditional correlations ---
model_cb_restricted <- lm(
  Response ~ Inflation + Unemployment,
  data = cb_restricted_results
)

model_cb_freeflow <- lm(
  Interest.Rate ~ Inflation + Unemployment,
  data = cb_freeflow_results
)

cb_hightemp_results <- lm(
  Interest.Rate ~ Inflation + Unemployment,
  data = cb_hightemp_results
)

# --- Save central bank heatmaps ---

# --- Arrange all plots ---
if (CM == TRUE) {
    theory_heatmap <- theory_heatmap + theme(text = element_text(family = "CM", size = 12))
    taylor_smooth_heatmap <- taylor_smooth_heatmap + theme(text = element_text(family = "CM", size = 12))
    llm_heatmap <- llm_heatmap + theme(text = element_text(family = "CM", size = 12))
}

ggsave("Graphs/central_bank_heatmap_restricted.pdf", plot = central_bank_heatmap_restricted, width = 8, height = 8)
ggsave("Graphs/central_bank_heatmap_freeflow.pdf", plot = central_bank_heatmap_freeflow, width = 8, height = 8)
ggsave("Graphs/central_bank_heatmap_hightemp.pdf", plot = central_bank_heatmap_hightemp, width = 8, height = 8)
