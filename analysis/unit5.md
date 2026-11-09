# Unit 5: Connecting the Tables

## Dataset and definitions

These queries use the existing instructor-provided `ex603_data` database, not the Unit 2 reset script. Producers are flights, actors are passengers, events are bookings, and airports are the catalog connected through flight_routes. I select SGN as the catalog tag. Failure retains Unit 4's exact definition: cancellation_reason = 'Passenger no show'. Historical events are from 2023; present active flags do not necessarily describe their historical state.

## Task 5.1

The three-table report returns 200 bookings with passenger names, flight numbers, and booking timestamps. A reservation support dashboard could use it to locate who made a reservation, the associated flight, and when it was booked. Identifiers remain visible to distinguish names that might be duplicated.

The SGN traversal returns flights 1, 2, 4, 5, 7, 8, 9, 10, and 12. Investigation target 2 (VN202) appears; target 3 (VN203) does not. Thus the targets do not share this particular airport tag. The junction table represents multiple airports per flight and multiple flights per airport without repeating flight details. Without it, lists embedded in a field or repeated airport columns would complicate filtering and risk inconsistent relationships. Airport association alone does not establish itinerary direction or explain no-shows.

The self join compares each target to other flights from its origin country. VN202 has 16 bookings and an 18.75% recorded no-show rate, versus VN206's 21 and 4.76% and VN211's 16 and 6.25%. VN203 has 13 bookings and 15.38%, versus Korean peers VN205 (18, 0%), VN212 (17, 5.88%), and VN213 (11, 0%). VN203 is currently inactive; its peers are active. It shares its 320-seat capacity with VN205, so equal capacity does not imply equal outcomes. These descriptive comparisons suggest follow-up; they do not isolate a cause, prove significance, or measure seat utilization over departures.

## Task 5.2

The LEFT JOIN returns 202 rows: 200 bookings plus two unmatched flight rows. The INNER JOIN returns 200 rows and includes 13 distinct producers. Of 15 total producers, **2 are excluded: flight 14 (VN214) and flight 15 (VN215)**. Counting distinct identifiers prevents repeated bookings from inflating producer counts.

The RIGHT JOIN reverses the table order and returns the same 202 records. Both directional EXCEPT ALL checks return zero differences, verifying multiplicity as well as membership. FULL OUTER JOIN also returns 202 rows here. It can additionally reveal events with no matching producer, but the current NOT NULL foreign key prevents such orphans. In less constrained imports it could expose them.

NOT EXISTS tests for the absence of a matching booking for each flight. EXCEPT subtracts the distinct set of booked flight identifiers from all flight identifiers; both return 14 and 15, and both directional difference counts are zero.

No events means no matching booking in this dataset, not proof that a flight never operated. Both flights are marked active. They may be unpublished, lack demand, have incomplete imported history, or have an onboarding issue; these explanations require investigation. An inner-join-only report hides them and can make participation look complete. Leadership should reconcile availability and booking capture, then assign an owner to resolve any confirmed setup issue or review demand. A no-show rate for these flights is undefined, rather than zero.

## Task 5.3

Two five-row airport relations produce 25 ordered candidate airport pairs: 5 x 5 = 25, confirmed by the actual CROSS JOIN count. This is useful for a route-planning candidate matrix, including five same-airport pairs that planners would normally filter out. The pairs are hypothetical, not observed routes. A Cartesian product in a booking report could instead indicate a missing join predicate and inflate totals.

The full executed SQL and execution plan are preserved in `unit5-evidence/unit5-task3-results.txt`. PostgreSQL chose a **Hash Join** between bookings and passengers followed by a **Nested Loop** to flights, using **Memoize** and a primary-key index scan. It sequentially scanned 200 bookings and 30 passengers. The passenger estimate was 100 rows, showing imperfect statistics. The passenger hash used 10 kB and one batch. Memoize recorded 187 hits and 13 misses: only 13 flight index lookups were needed for 200 events. The final booking-ID sort used quicksort and 40 kB. Execution was 0.436 ms in this local run, not a production benchmark.

Reading most of a small table makes sequential scanning reasonable. Hashing the small passenger relation supports equality matches, while cached unique flight lookups make the nested loop inexpensive. As bookings grow, scanning and sorting all events become more expensive; sort or hash memory pressure can cause disk work. More distinct flight identifiers can reduce cache reuse. Costs are planner estimates, not milliseconds, and observed timings vary with caching and hardware.

### Reflection (150–250 words)

PostgreSQL can choose a different join algorithm when the amount or distribution of data changes, even if the SQL stays the same. In this run, the passenger hash contained 30 rows, while repeated flight identifiers made the nested loop efficient: Memoize avoided 187 repeated index lookups. If the booking table grew to millions of rows and referenced many more distinct flights, that reuse could fall. A hash join against flights might then cost less than repeated index probes.

I noticed that indexes can change the tradeoff too. A selective booking-date filter with a suitable index could return only a few events, making nested loops into indexed passenger and flight keys attractive. For large inputs already ordered on their join keys, a merge join could become competitive by avoiding additional sorting. Merely adding an index does not guarantee that PostgreSQL will use it.

Memory and statistics also matter. Larger hash tables may require multiple batches and disk access, while a larger final sort could spill beyond available memory. Updated statistics after substantial loading can improve estimates of row counts and matching values; the passenger estimate here exceeded the actual count. I think it would compare actual plans on representative workloads before selecting an optimization.

## Verification and screenshots

All three SQL files ran unchanged using psql with ON_ERROR_STOP against ex603_data. Raw query/output transcripts are in unit5-evidence. They were captured from a local results viewer populated directly by psql executions, not manually constructed result tables. Unit5 - 5.3-3.png contains the full plan; Unit5 - 5.3-2.png contains both source counts and the actual product count. The screenshot run repeated the plan with the same algorithms; elapsed timings differ from the earlier transcript run. The anonymous repository URL returned HTTP 200; a logged-out browser check remains on the submission checklist. No changes have been pushed.

### Unit 5 screenshots

- [Unit5 - 5.1-1](../screenshots/Unit5%20-%205.1-1.png)
- [Unit5 - 5.1-2](../screenshots/Unit5%20-%205.1-2.png)
- [Unit5 - 5.1-3](../screenshots/Unit5%20-%205.1-3.png)
- [Unit5 - 5.2-1](../screenshots/Unit5%20-%205.2-1.png)
- [Unit5 - 5.2-2](../screenshots/Unit5%20-%205.2-2.png)
- [Unit5 - 5.2-3](../screenshots/Unit5%20-%205.2-3.png)
- [Unit5 - 5.2-4](../screenshots/Unit5%20-%205.2-4.png)
- [Unit5 - 5.2-5](../screenshots/Unit5%20-%205.2-5.png)
- [Unit5 - 5.2-6](../screenshots/Unit5%20-%205.2-6.png)
- [Unit5 - 5.2-7](../screenshots/Unit5%20-%205.2-7.png)
- [Unit5 - 5.2-8](../screenshots/Unit5%20-%205.2-8.png)
- [Unit5 - 5.2-9](../screenshots/Unit5%20-%205.2-9.png)
- [Unit5 - 5.3-1](../screenshots/Unit5%20-%205.3-1.png)
- [Unit5 - 5.3-2](../screenshots/Unit5%20-%205.3-2.png)
- [Unit5 - 5.3-3](../screenshots/Unit5%20-%205.3-3.png)
