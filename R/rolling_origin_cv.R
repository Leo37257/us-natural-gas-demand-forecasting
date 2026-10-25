suppressPackageStartupMessages(library(forecast))
raw <- read.csv("U.S._Natural_Gas_Total_Consumption.csv", skip = 4, header = TRUE,
                stringsAsFactors = FALSE)
colnames(raw) <- c("Month", "Consumption")
raw$Date <- as.Date(paste0("01 ", raw$Month), format = "%d %b %Y")
raw <- raw[order(raw$Date), ]
df <- raw[raw$Date >= as.Date("2006-01-01") & raw$Date <= as.Date("2025-12-31"), ]
gas_ts <- ts(df$Consumption, start = c(2006, 1), frequency = 12)

# Fixed lambda from the project's own training window, so it is not re-tuned
# at every origin either.
train_ts <- window(gas_ts, end = c(2023, 12))
lambda_bc <- BoxCox.lambda(train_ts)

# Same structure the project selected, held fixed across origins. Only the
# coefficients are re-estimated - matching how hw() is treated.
f_arima_fixed <- function(y, h) forecast(
  Arima(y, order = c(0, 0, 1), seasonal = list(order = c(0, 1, 1), period = 12),
        lambda = lambda_bc, method = "ML"), h = h)
f_hw   <- function(y, h) hw(y, seasonal = "multiplicative", h = h)
f_reg  <- function(y, h) forecast(tslm(y ~ trend + season), h = h)
f_sn   <- function(y, h) snaive(y, h = h)

H <- 24; INITIAL <- 120
fns <- list(`Seasonal Naive` = f_sn, `Regression (Trend + Season)` = f_reg,
            `SARIMA(0,0,1)(0,1,1)` = f_arima_fixed, `Holt-Winters (mult.)` = f_hw)
cv <- lapply(fns, function(f) tsCV(gas_ts, f, h = H, initial = INITIAL))

scale <- mean(abs(diff(as.numeric(gas_ts), lag = 12)), na.rm = TRUE)
byh <- do.call(rbind, lapply(names(cv), function(m) {
  e <- cv[[m]]
  data.frame(Model = m, h = seq_len(ncol(e)),
             MASE = colMeans(abs(e), na.rm = TRUE) / scale,
             RMSE = sqrt(colMeans(e^2, na.rm = TRUE)))
}))
overall <- aggregate(cbind(RMSE, MASE) ~ Model, byh, mean)
cat("\n=== 同等条件：结构固定，仅重估参数 ===\n\n")
print(overall[order(overall$MASE), ], row.names = FALSE, digits = 5)
cat("\n=== MASE by horizon ===\n")
sel <- byh[byh$h %in% c(1, 6, 12, 24), c("Model", "h", "MASE")]
print(reshape(sel, idvar = "Model", timevar = "h", direction = "wide"),
      row.names = FALSE, digits = 4)
saveRDS(byh, "cv_fair_byh.rds")
