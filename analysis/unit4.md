# Unit 4: From Rows to Insight

## Population and definitions

I used the same instructor-provided `airline.sql` dataset as Unit 3, loaded into `ex603_data`, rather than the project's Unit 2 schema. The event table is `bookings`, the producer identifier is `flight_id`, the actor identifier is `passenger_id`, and the numeric theme metric is `fare_paid`. All 200 bookings are in 2023.

A failure means a booking whose `cancellation_reason` is exactly `Passenger no show`, consistent with the Unit 3 investigation. Every booking status remains in the denominator, including confirmed, cancelled, and disputed. A missing reason means no recorded no-show, not a proven success. The broader cancellation rate is a different measure: 34/200 = 17%; disputes are 10/200 = 5%. Neither is substituted for the recorded no-show rate of 12/200 = 6%.

For the requested regional analysis, I use `booking_country` as the booking-market region. This is a country-level grouping, not a claim about flight origin or passenger residence. Aggregating the event table directly avoids multiplying bookings through the many-to-many route or service tables. Producer summaries contain the 13 producers with bookings; producers 14 and 15 have no events and no estimable no-show rate.

## Task 4.1: Measure the platform

### 4.1a: Overall metric statistics

There are 200 bookings and 200 non-null fares, totaling 3,628.19 in the dataset's unspecified currency units. The average is 18.14, the minimum is 0.00, and the maximum is 70.86. All 30 distinct passengers appear. The zero-fare count is 34. The region-and-status query shows that all 34 cancelled bookings have zero fares; all other status groups have positive totals. A separate record check confirmed that zero fares and cancellations coincide exactly. Zero is permitted by the supplied schema, so I would ask how refunds and cancellations are recorded before treating these values as errors. The stored fare total is not automatically recognized revenue or profit.

### 4.1b: Producer activity and average fare

| Producer ID | Bookings | Average fare |
|---|---:|---:|
| 6 | 21 | 17.84 |
| 8 | 20 | 22.63 |
| 10 | 19 | 20.97 |
| 5 | 18 | 23.06 |
| 7 | 18 | 18.33 |
| 12 | 17 | 18.27 |
| 2 | 16 | 17.02 |
| 11 | 16 | 11.94 |
| 9 | 14 | 14.17 |
| 3 | 13 | 13.36 |
| 1 | 11 | 16.03 |
| 13 | 11 | 19.86 |
| 4 | 6 | 19.49 |

Producer 6 has the highest booking count, while producer 5 has the highest average fare among producers with events. More activity does not necessarily mean a higher fare. Cancellation frequency and fare mix both affect these averages.

### 4.1c: A minimum-volume screen

I chose **15 bookings** and applied `HAVING COUNT(*) >= 15`. This is just above the 200/15 = 13.33 bookings per producer across the full producer catalogue and retains eight producers covering 145 bookings (72.5% of events). It is a practical triage rule for this small teaching dataset, not a statistically established reliability cutoff. Even 15 bookings are insufficient for strong conclusions about a rare outcome.

The qualifying producer IDs are 2, 5, 6, 7, 8, 10, 11, and 12. Producer 2 has 3 no-shows in 16 bookings (18.75%), the highest qualifying rate. The remaining qualifying rates range from 0% to 6.25%. Lower-volume producers remain visible in Part A and can merit a preliminary review without qualifying for the high-volume baseline.

### 4.1d: Region and status together

Grouping by `booking_country` and `booking_status` yields 14 observed combinations. Thailand has 11 cancellations and 29 confirmed bookings, with no disputed row because no such events occur. Korea has 5 cancellations, 30 confirmed bookings, and 4 disputes. The other regions have 2 disputes each. Each combination has its own count, average fare, total fare, and no-show count. These rows reveal status composition hidden by a country-wide average; a missing combination is not an unknown status.

### Who acts, what is hidden, and what comes next?

The **Director of Airline Operations** would act on the per-producer breakdown by assigning a review of producer 2 and a smaller exploratory review of producer 3. The overall average fare hides the fare distribution, zero-fare cancellations, and differences in markets and status mix. A booking count hides which passengers generated those events and whether a few repeat passengers account for the failures. The 6% platform rate hides producer variation and different booking volumes.

Next I would inspect the underlying no-show records, repeat-passenger concentration, fare distributions and medians by status, monthly trends, and producer-by-booking-country rates. I would also request refund definitions and operational context. Those checks can distinguish persistent issues from a small-sample fluctuation or a recording problem.

## Task 4.2: Build the leadership breakdown

### Part A: Two numbers in one pass

The two questions answered side by side are: **How many total bookings does each producer have?** and **How many of those bookings are recorded passenger no-shows?** `COUNT(*)` and `SUM(CASE ... ELSE 0 END)` answer both without a whole-query failure filter. NULL cancellation reasons contribute zero to the no-show numerator while remaining in the booking denominator.

Across the 13 producer rows, total bookings sum to 200 and no-shows sum to 12. Producer 2 contributes 3 of the 12 no-shows (25%), producer 3 contributes 2 (16.67%), and seven other producers contribute one each. Producers 5, 8, 10, and 13 record none. Producer 4's 16.67% rate comes from just one no-show among six bookings. See the leadership finding for the two recommended investigation priorities.

### Part B: Regional subtotals and grand total

The **Regional Director** needs one subtotal per booking market to allocate follow-up work, without reviewing individual status combinations or bookings.

| Region | Row type | Bookings | Fare total | No-shows | No-show rate |
|---|---|---:|---:|---:|---:|
| Japan | Regional subtotal | 43 | 691.00 | 1 | 2.33% |
| Korea | Regional subtotal | 39 | 780.43 | 3 | 7.69% |
| Singapore | Regional subtotal | 40 | 835.77 | 1 | 2.50% |
| Thailand | Regional subtotal | 40 | 707.31 | 4 | 10.00% |
| Vietnam | Regional subtotal | 38 | 613.68 | 3 | 7.89% |
| PLATFORM GRAND TOTAL | Grand total | 200 | 3,628.19 | 12 | 6.00% |

`ROLLUP(booking_country)` returns only the five regional subtotals and the grand total; it does not include status-level detail rows. The `row_type` label and `GROUPING()` identify the total explicitly. The grand total supports the platform-wide decision about the scale of the issue and provides a denominator for prioritizing resources. Individual regional rows alone do not state that overall result. The platform rate is computed from total failures divided by total bookings, not by averaging regional percentages.

### Part C: A two-step pipeline

The question is: **Among producers with at least 15 bookings, what is the pooled no-show baseline, and how does it compare with the average producer rate?**

The `producer_metrics` CTE first produces booking and no-show counts per producer. The outer query filters those summaries to the 15-booking threshold and aggregates them. Eight producers have 145 bookings and 7 no-shows, giving a booking-weighted baseline of **4.83%**. The unweighted mean producer rate is **5.15%**. The weighted baseline describes the chance that a booking in this qualifying cohort has a recorded no-show; the unweighted mean gives each producer equal influence. The full platform's 6.00% remains a separate population measure. Producer 2 exceeds both baselines, but these descriptive comparisons do not establish causation or statistical significance.

## Reflection

Conditional aggregation lets the database answer two related questions while reading the same population: how many bookings each producer received and how many were recorded no-shows. Each row contributes to the total, while CASE decides whether it also contributes to the failure count. This keeps the numerator and denominator aligned, including bookings with NULL cancellation reasons.

Two separate filtered queries can still be correct, but they require combining their results carefully. A producer with no failures may be absent from the failure result, so an inner join would silently lose that producer. Different filters or runs at different times can also create inconsistent populations unless both queries share a consistent transaction snapshot.

At a million rows, repeated scans can mean additional disk reads, CPU work, grouping, and communication between the database and client. A conditional aggregate can calculate both counts in one scan and return one compact result set. That usually reduces duplicated work, especially when most rows must be read anyway.

The improvement is not guaranteed: selective indexes, caching, parallel execution, and the query planner affect actual performance. I would compare execution plans and measured runtimes on representative data. The main benefit here is a clear, consistent calculation; the performance benefit should be verified rather than assumed.

## Execution evidence

Both SQL files ran unchanged with `psql -X -v ON_ERROR_STOP=1 -d ex603_data -f <file>`. All seven queries completed successfully. Each full, uncropped browser capture shows the complete query and the result returned by a local PostgreSQL-backed read-only viewer. The viewer executes the displayed SQL against `ex603_data` on page load; the images are not mock result tables. The screenshots are named `Unit4 - 4.1a.png` through `Unit4 - 4.2c.png` to map to the query labels.
