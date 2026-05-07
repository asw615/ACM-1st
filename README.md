# Advanced Cognitive Modelling, Project 1

WSLS vs Rescorla-Wagner RL agents in the matching pennies game, written for the AdvCogMod course.

## Files
- `ACM_P1.Rmd` contains the agent definitions and a single-condition simulation chunk.
- `run_plots.R` regenerates every figure in the report (three learning rates plus the two DAGs).
- `out/` holds the generated PNGs.

## Run
For a single interactive run, open `ACM_P1.Rmd` and knit. For the full set of figures, `Rscript run_plots.R`. Needs `tidyverse`, `cowplot`, and `gridExtra`.

## Parameters
WSLS noise is fixed at 0.25. The RL learning rate (`alpha`) is set inline in the simulation chunk and was swept over {0.1, 0.5, 0.9} for the report.
