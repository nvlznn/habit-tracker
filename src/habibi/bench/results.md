# habibi — date-key lookup benchmark

Workload: 10000 queries per (impl, N), seed=42.
Half of queries are guaranteed hits, half are random window picks.
Bitmap window is sized ~3x N so the set is moderately sparse.

| N | Impl | Build (us) | contains (ns/op) | add (ns/op) | hits | mem (bytes) |
|---:|---|---:|---:|---:|---:|---:|
| 100 | HashSet | 121 | 57.5 | 142.5 | 6680 | 2400 |
| 100 | SortedArray | 299 | 229.3 | 115.7 | 6680 | 800 |
| 100 | Bitmap | 212 | 42.7 | 1016.2 | 6680 | 38 |
| 1000 | HashSet | 63 | 16.9 | 23.0 | 6715 | 24000 |
| 1000 | SortedArray | 737 | 70.8 | 496.0 | 6715 | 8000 |
| 1000 | Bitmap | 52 | 36.8 | 38.6 | 6715 | 375 |
| 10000 | HashSet | 600 | 16.4 | 1448.1 | 6657 | 240000 |
| 10000 | SortedArray | 43293 | 68.9 | 9139.0 | 6657 | 80000 |
| 10000 | Bitmap | 32 | 4.7 | 6.7 | 6657 | 3750 |
| 100000 | HashSet | 5621 | 9.1 | 11.9 | 6610 | 2400000 |
| 100000 | SortedArray | 4220023 | 94.3 | 87210.4 | 6610 | 800000 |
| 100000 | Bitmap | 258 | 4.7 | 4.4 | 6610 | 37500 |

## Notes
- HashSet: O(1) avg contains/add, ~24 B/entry overhead.
- SortedArray: O(log n) contains, O(n) add (shift). Add cost should grow visibly with N.
- Bitmap: O(1) everything, fixed memory = ceil(window/8) bytes regardless of fill rate.
- Bitmap inserts in this benchmark go to days within its window; out-of-range writes would be silently dropped (intentional — a fixed-window bitmap trades unbounded range for constant memory).
