# Advanced Cognitive Modelling, Project 1

WSLS vs Rescorla-Wagner RL agents in the matching pennies game, written for the AdvCogMod course.

## Files
- `ACM_P1.Rmd` contains the agent definitions, simulation loop, and plots.
- `out/` contains the model diagrams (`wsls_diagram.svg`, `rl_diagram.svg`) plus PNG copies.

## Run
Open `ACM_P1.Rmd` in RStudio and knit, or run the chunks interactively. Needs `tidyverse`, `cowplot`, and `gridExtra`.

## Parameters
WSLS noise is fixed at 0.25. The RL learning rate (`alpha`) is set inline in the simulation chunk and was swept over {0.1, 0.5, 0.9} for the report.

## Models
The agent functions adapt the AdvCogMod 2023 codebook at https://fusaroli.github.io/AdvancedCognitiveModeling2023/. Full verbal and formal model descriptions live in the report.
