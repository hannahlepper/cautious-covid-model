
s_func <- function(x, midpoint, steepness) {
    1/(1+exp(-steepness * (x - midpoint)))
}

s_function_df <- data.frame(x_t = rep(seq(0,10,0.1), times = 3), 
    sigma_star = rep(c(0.2, 0.5, 0.8), each = length(seq(0,10,0.1))))
s_function_df$sigma_t = s_func(s_function_df$x_t, 3, 5) *s_function_df$sigma_star

library(ggplot2)

png("plots/sigmoid_transmission.png", width = 15, height = 10, units = "cm", res = 300)
ggplot(s_function_df, aes(x_t, sigma_t, col = as.factor(sigma_star))) + 
    geom_line() +
    labs(col = "sigma_star") + 
    theme_bw()
dev.off()
