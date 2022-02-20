#Simple SIR code

library(deSolve)
library(plyr)
library(tidyverse)

sir <- function(time, state, parameters) {
    with(as.list(c(state, parameters)), {

        #Number of people infected that a person knows given they already know at least one person, on average
        x_t = 1 + ((circle-1)/N) * (I + R)
        log_fac = 1/(1 + exp(-kappa * (x_t - x_m)))
        omeg_t = omeg_star * log_fac

        #Proportion of the population who knows at least 1 case
        prop_know = 1 - (1 - ((I+R)/N))^circle

        dS = - bet*S*I - prop_know * S
        dSk = - (1 - omeg_t)*bet*Sk*I + prop_know * S
        dE = bet*S*I + (1 - omeg_t)*bet*Sk*I - alpha*E
        dI = alpha*E + - gam * I
        dR = gam * I

        dsk_tot = max(prop_know * S, 0)

        return(list(c(dS, dSk, dE, dI, dR, dsk_tot), 
                    omeg_t = omeg_t, x_t = x_t))
    })
}

parameters <- data.frame(bet=0.00093,
                         gam=1/7.5, 
                         alpha = 1/5, 
                         omeg_star = c(0., 0.2, 0.5, 0.8, 0.99), 
    N = sum(init), circle = 100, kappa = 5, x_m = 3)

init <- c(S=9999 - 9999*(1 - (1 - 1/10000)^parameters$circle[1]), 
          Sk = 9999*(1 - (1 - 1/10000)^parameters$circle[1]), 
          E = 0, I = 1, R = 0,
          sk_tot = 9999*(1 - (1 - 1/10000)^parameters$circle[1]))
time <- seq(0,365,by=1)

out_ls <- lapply(1:5, function(s) ode(y=init,times=time,sir,parms=parameters[s,]))

out_df <- lapply(out_ls, as.data.frame) %>%
    bind_rows() %>%
    mutate(., sigma_star = rep(c(0, 0.2, 0.5, 0.8, 0.99), each = 366))

png("plots/epidemic_curve.png", width = 15, height = 10, units = "cm", res = 300)
ggplot(out_df, aes(time, I, col = as.factor(sigma_star))) + 
    geom_line() +
    scale_x_continuous(limits = c(0, 50)) +
    theme_bw() +
    labs(y = "Number of infectious individuals", 
        x = "Time in days since introduction of COVID-19",
        col = "Level of\ncautiousness")
dev.off()

ggplot(subset(out_df, sigma_star == 0.99), aes(time, I)) + 
    geom_line() +
    scale_x_continuous(limits = c(300, 365)) +
    scale_y_continuous(limits = 0, 1)

#Smaller ss jumps 
parameters <- data.frame(bet=0.00093,
                         gam=1/7.5, 
                         alpha = 1/5, 
                         omeg_star = seq(0, 1, by = 0.001), 
    N = 10000, circle = 100, kappa = 5, x_m = 3)
out_ls <- lapply(1:nrow(parameters), 
    function(s) ode(y=init,times=time,sir,parms=parameters[s,]))

out_df <- lapply(out_ls, as.data.frame) %>%
    lapply(., function(mod) mod[nrow(mod),]) %>%
    bind_rows() %>%
    mutate(., sigma_star = seq(0, 1, by = 0.001))

ggplot(out_df, aes(sigma_star, x_t)) + geom_point()

png("plots/number_of_cases.png", width = 15, height = 10, units = "cm", res = 300)
ggplot(out_df, aes(sigma_star, I + R)) + 
    geom_line() +
    scale_x_continuous(limits = c(0.75, 1.0)) +
    labs(x = "Level of cautiousness", y = "Number of cases after 1 year") +
    theme_bw()
dev.off()

png("plots/prior_knowledge.png", width = 15, height = 10, units = "cm", res = 300)
ggplot(out_df, aes(sigma_star, sk_tot)) + 
    geom_line() +
    theme_bw() +
    scale_y_continuous(limits = c(8400, 8600))
    labs(y = "Number of people who knew at least one case before infection", 
        x = "Level of cautiousness")
dev.off()
