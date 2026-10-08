::: {.fc-data}
Seconds per simulated year; in brackets, the IBM's multiple of fleet's time.

| setting | EIR | fleet | IBM 10,000 | IBM 30,000 | IBM 50,000 |
|:--|--:|--:|--:|--:|--:|
| nothing deployed | 1 | 0.83 | 1.18 (1.4×) | 2.22 (2.7×) | 3.34 (4.0×) |
|  | 3 | 0.94 | 1.44 (1.5×) | 2.63 (2.8×) | 3.70 (3.9×) |
|  | 10 | 0.94 | 1.56 (1.7×) | 3.01 (3.2×) | 4.39 (4.7×) |
| seasonal programme | 1 | 1.97 | 1.38 (0.7×) | 2.71 (1.4×) | 4.49 (2.3×) |
|  | 3 | 2.10 | 1.28 (0.6×) | 2.71 (1.3×) | 4.41 (2.1×) |
|  | 10 | 2.05 | 1.17 (0.6×) | 3.48 (1.7×) | 5.13 (2.5×) |

One run of each model, alone on one core (Snapdragon X 12-core X1E80100 @ 3.40 GHz), over 10 years from set_equilibrium()'s seed, start-up excluded: fleet's takes 0.67 to 1.5 s, the IBM's 3.5 to 3.9 s at 10,000 people and 7.7 to 8.4 s at 50,000. fleet's cost does not depend on the population. The seasonal programme is case management with chloroquine and primaquine radical cure, bed nets and indoor spraying, running from the first day. `CMP_PARASITE=pv validations/02-scenarios/speed.R` makes this table.
:::
