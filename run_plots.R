### Generate every figure for the report in one pass.
### Run from the repo root: Rscript run_plots.R

pacman::p_load(tidyverse, cowplot, gridExtra, grid)

trials <- 120
set.seed(2001)

### Agents (kept identical to ACM_P1.Rmd) -----------------------------------

agent_wsls <- function(prevChoice, feedback, noise = 0) {
  if (!prevChoice %in% c(0, 1)) stop("Previous choice must be 0 or 1.")
  if (!feedback %in% c(0, 1)) stop("Feedback must be 0 or 1.")
  if (!is.numeric(noise) || noise < 0 || noise > 1) stop("Noise must be a probability between 0 and 1.")
  choice <- ifelse(feedback == 1, prevChoice, 1 - prevChoice)
  if (noise > 0 && runif(1) < noise) {
    choice <- sample(c(0, 1), 1)
  }
  return(choice)
}

agent_rl <- function(belief, opponent_prev_choice, alpha = 0.1) {
  if (!opponent_prev_choice %in% c(0, 1)) stop("Opponent's previous choice must be 0 or 1.")
  if (!is.numeric(alpha) || alpha < 0 || alpha > 1) stop("Alpha must be between 0 and 1.")
  belief <- belief + alpha * (opponent_prev_choice - belief)
  choice_prob <- 1 - belief
  choice <- rbinom(1, 1, choice_prob)
  return(list(choice = choice, choice_prob = choice_prob, belief = belief))
}

### Single-game simulator ----------------------------------------------------

run_game <- function(trials, wsls_noise = 0.25, rl_alpha = 0.1) {
  wsls <- rep(NA, trials)
  rl <- rep(NA, trials)
  feedback <- rep(NA, trials)
  cprob <- rep(NA, trials)
  belief <- rep(NA, trials)

  wsls[1] <- sample(c(0, 1), 1)
  belief[1] <- 0.5
  cprob[1] <- 0.5
  rl[1] <- rbinom(1, 1, 0.5)

  for (t in 2:trials) {
    feedback[t - 1] <- ifelse(wsls[t - 1] == rl[t - 1], 1, 0)
    wsls[t] <- agent_wsls(wsls[t - 1], feedback[t - 1], noise = wsls_noise)
    step <- agent_rl(belief[t - 1], wsls[t - 1], alpha = rl_alpha)
    rl[t] <- step$choice
    cprob[t] <- step$choice_prob
    belief[t] <- step$belief
  }
  feedback[trials] <- ifelse(wsls[trials] == rl[trials], 1, 0)

  tibble(
    trial = 1:trials,
    Self_WSLS = wsls,
    Opponent_RL = rl,
    Feedback_WSLS = feedback,
    Choice_Prob_RL = cprob,
    Belief_RL = belief
  ) %>% mutate(Cumulative_Performance = cumsum(Feedback_WSLS) / row_number())
}

### Plot helpers -------------------------------------------------------------

plot_pair <- function(df, lr_label) {
  p_choices <- ggplot(df, aes(x = trial)) +
    geom_line(aes(y = Self_WSLS, color = "WSLS Agent")) +
    geom_line(aes(y = Opponent_RL + 0.05, color = "RL Agent"), linetype = "dashed") +
    labs(title = paste0("WSLS vs. RL (", lr_label, ")"), y = "Choice (0/1)") +
    theme_cowplot() + ylim(-0.1, 1.1)
  p_perf <- ggplot(df, aes(x = trial, y = Cumulative_Performance)) +
    geom_line(color = "purple", linewidth = 1) +
    geom_hline(yintercept = 0.5, linetype = "dashed") +
    labs(title = paste0("WSLS Performance vs. RL (", lr_label, ")"), y = "Proportion Wins") +
    theme_cowplot() + ylim(0, 1)
  arrangeGrob(p_choices, p_perf, nrow = 2)
}

plot_prob <- function(df, lr_label) {
  ggplot(df, aes(x = trial, y = Choice_Prob_RL)) +
    geom_line(color = "blue", linewidth = 1) +
    labs(title = paste0("RL Agent Choice Probability of Choosing 1 (", lr_label, ")"),
         y = "Choice Probability") +
    theme_cowplot() + ylim(0, 1)
}

### Run three conditions and write PNGs --------------------------------------

dir.create("out", showWarnings = FALSE)

run_and_save <- function(alpha_val, label, suffix) {
  df <- run_game(trials, wsls_noise = 0.25, rl_alpha = alpha_val)
  ggsave(paste0("out/sim_pair_", suffix, ".png"),
         plot = plot_pair(df, label), width = 7, height = 6, dpi = 150)
  ggsave(paste0("out/sim_prob_", suffix, ".png"),
         plot = plot_prob(df, label), width = 7, height = 3.5, dpi = 150)
  invisible(df)
}

run_and_save(0.1, "0.1 LR", "lr01")
run_and_save(0.5, "0.5 LR", "lr05")
run_and_save(0.9, "0.9 LR", "lr09")

### DAG figures (manual ggplot, kept simple) ---------------------------------

dag_theme <- theme_void() +
  theme(plot.title = element_text(hjust = 0.5, size = 13, face = "bold"),
        plot.margin = margin(10, 10, 10, 10))

draw_node <- function(x, y, label, fill = "white", width = 0.55, height = 0.32) {
  list(
    annotate("rect", xmin = x - width / 2, xmax = x + width / 2,
             ymin = y - height / 2, ymax = y + height / 2,
             fill = fill, color = "black"),
    annotate("text", x = x, y = y, label = label, parse = TRUE, size = 4)
  )
}

draw_edge <- function(x1, y1, x2, y2) {
  annotate("segment", x = x1, y = y1, xend = x2, yend = y2,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed"),
           linewidth = 0.5)
}

## WSLS DAG. Nodes: y_{t-1}, r_{t-1}, epsilon, y_t.
wsls_dag <- ggplot() +
  draw_node(1, 2, "y[t-1]") +
  draw_node(3, 2, "r[t-1]") +
  draw_node(2, 3, "epsilon") +
  draw_node(2, 1, "y[t]") +
  draw_edge(1, 1.85, 1.85, 1.15) +
  draw_edge(3, 1.85, 2.15, 1.15) +
  draw_edge(2, 2.85, 2, 1.15) +
  coord_fixed(xlim = c(0.3, 3.7), ylim = c(0.5, 3.5), clip = "off") +
  labs(title = "WSLS agent") + dag_theme

ggsave("out/wsls_dag.png", wsls_dag, width = 4.5, height = 3.5, dpi = 200, bg = "white")

## RL DAG. Nodes: b_{t-1}, o_{t-1}, alpha, b_t, a_t.
rl_dag <- ggplot() +
  draw_node(1, 3, "b[t-1]") +
  draw_node(3, 3, "o[t-1]") +
  draw_node(2, 4, "alpha") +
  draw_node(2, 2, "b[t]") +
  draw_node(2, 1, "a[t]") +
  draw_edge(1, 2.85, 1.85, 2.15) +
  draw_edge(3, 2.85, 2.15, 2.15) +
  draw_edge(2, 3.85, 2, 2.15) +
  draw_edge(2, 1.85, 2, 1.15) +
  coord_fixed(xlim = c(0.3, 3.7), ylim = c(0.5, 4.5), clip = "off") +
  labs(title = "Rescorla-Wagner agent (non-matcher)") + dag_theme

ggsave("out/rl_dag.png", rl_dag, width = 4.5, height = 4.5, dpi = 200, bg = "white")

cat("Done. PNGs written to out/.\n")
