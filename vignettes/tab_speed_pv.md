::: {.fc-data}
Seconds per simulated year; in brackets, the IBM's multiple of fleet's time.

| setting | EIR | fleet | IBM 10,000 | IBM 30,000 | IBM 50,000 |
|:--|--:|--:|--:|--:|--:|
| nothing deployed | 1 | 0.65 | 1.19 (1.8×) | 2.33 (3.6×) | 3.29 (5.1×) |
|  | 3 | 0.63 | 1.31 (2.1×) | 2.58 (4.1×) | 3.68 (5.8×) |
|  | 10 | 0.63 | 1.56 (2.5×) | 3.19 (5.1×) | 4.54 (7.3×) |
| seasonal programme | 1 | 0.92 | 1.22 (1.3×) | 2.76 (3.0×) | 4.17 (4.5×) |
|  | 3 | 0.91 | 1.23 (1.4×) | 2.72 (3.0×) | 4.48 (5.0×) |
|  | 10 | 0.91 | 1.18 (1.3×) | 3.33 (3.7×) | 4.61 (5.1×) |

One run of each model, alone on one core (Snapdragon X 12-core X1E80100 @ 3.40 GHz), over 10 years from set_equilibrium()'s seed, start-up excluded: fleet's takes 0.60 to 1.0 s, the IBM's 3.4 to 3.7 s at 10,000 people and 7.9 to 8.2 s at 50,000. fleet's cost does not depend on the population. The seasonal programme is case management with chloroquine and primaquine radical cure, bed nets and indoor spraying, running from the first day. `CMP_PARASITE=pv validations/02-scenarios/speed.R` makes this table.
:::
