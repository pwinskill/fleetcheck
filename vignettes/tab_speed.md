::: {.fc-data}
Seconds per simulated year; in brackets, the IBM's multiple of fleet's time.

| setting | EIR | fleet | IBM 10,000 | IBM 30,000 | IBM 50,000 |
|:--|--:|--:|--:|--:|--:|
| nothing deployed | 3 | 0.081 | 1.61 (20×) | 3.21 (40×) | 4.37 (54×) |
|  | 20 | 0.079 | 1.92 (24×) | 3.64 (46×) | 4.99 (63×) |
|  | 120 | 0.075 | 2.01 (27×) | 4.85 (65×) | 7.03 (94×) |
| seasonal programme | 3 | 0.10 | 2.10 (20×) | 4.14 (39×) | 6.32 (60×) |
|  | 20 | 0.095 | 2.18 (23×) | 4.96 (52×) | 7.78 (82×) |
|  | 120 | 0.096 | 2.36 (25×) | 5.61 (58×) | 8.40 (88×) |

One run of each model, alone on one core (Snapdragon X 12-core X1E80100 @ 3.40 GHz), over 10 years from set_equilibrium()'s seed, start-up excluded: fleet's takes 0.060 to 0.14 s, the IBM's 0.74 to 0.96 s at 10,000 people and 3.0 to 3.6 s at 50,000. fleet's cost does not depend on the population. The seasonal programme is case management, bed nets, indoor spraying, SMC and RTS,S, running from the first day. `validations/02-scenarios/speed.R` makes this table.
:::
