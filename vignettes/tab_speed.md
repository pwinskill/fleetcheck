Seconds per simulated year, one run of each model alone on one core (Snapdragon X 12-core X1E80100 @ 3.40 GHz), over 10 years from set_equilibrium()'s seed, start-up excluded: fleet's takes 0.060 to 0.14 s, the IBM's 0.74 to 0.96 s at 10,000 people and 3.0 to 3.6 s at 50,000. In brackets, the IBM's multiple of fleet's time; fleet's cost does not depend on the population. The seasonal programme is case management, bed nets, indoor spraying, SMC and RTS,S, running from the first day. `validations/02-scenarios/speed.R` makes this table.

| setting | EIR | fleet | IBM, 10,000 people | IBM, 30,000 people | IBM, 50,000 people |
|:--|--:|--:|--:|--:|--:|
| nothing deployed |   3 | 0.081 s | 1.61 s (20×) | 3.21 s (40×) | 4.37 s (54×) |
|  |  20 | 0.079 s | 1.92 s (24×) | 3.64 s (46×) | 4.99 s (63×) |
|  | 120 | 0.075 s | 2.01 s (27×) | 4.85 s (65×) | 7.03 s (94×) |
| seasonal programme |   3 | 0.10 s | 2.10 s (20×) | 4.14 s (39×) | 6.32 s (60×) |
|  |  20 | 0.095 s | 2.18 s (23×) | 4.96 s (52×) | 7.78 s (82×) |
|  | 120 | 0.096 s | 2.36 s (25×) | 5.61 s (58×) | 8.40 s (88×) |
