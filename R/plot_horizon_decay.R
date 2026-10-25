suppressPackageStartupMessages({library(ggplot2)})
byh <- readRDS("cv_fair_byh.rds")
byh$Model <- factor(byh$Model, levels = c(
  "Regression (Trend + Season)", "Holt-Winters (mult.)",
  "Seasonal Naive", "SARIMA(0,0,1)(0,1,1)"))

p <- ggplot(byh, aes(h, MASE, colour = Model)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey45") +
  geom_line(linewidth = 0.9) +
  annotate("text", x = 1.5, y = 1.02, label = "seasonal naive parity",
           hjust = 0, size = 3, colour = "grey35") +
  scale_x_continuous(breaks = c(1, 6, 12, 18, 24)) +
  scale_colour_manual(values = c("#1b7837", "#762a83", "#808080", "#d95f02")) +
  labs(title = "Forecast accuracy decays differently by model",
       subtitle = "Rolling-origin CV, ~100 origins, U.S. monthly natural gas consumption 2006-2025",
       x = "Forecast horizon (months ahead)", y = "MASE  (lower is better)",
       caption = "Holt-Winters wins at h=1 but crosses naive parity by h=12; regression stays below 1.0 throughout.") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        plot.caption = element_text(hjust = 0, colour = "grey30"))

ggsave("mase_by_horizon.png", p, width = 8, height = 4.8, dpi = 150)
cat("saved mase_by_horizon.png\n")
