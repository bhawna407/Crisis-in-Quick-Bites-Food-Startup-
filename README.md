**QuickBite Express — Crisis Overview Report**

**Project Background**

QuickBite Express is a Bengaluru-based food-tech startup (founded 2020) operating a two-sided marketplace connecting customers with restaurants and cloud kitchens. In June 2025, a viral social media exposé on food-safety violations at partner restaurants, compounded by a week-long delivery outage during monsoon season, triggered a severe trust collapse. Competitors moved in aggressively during the vacuum, accelerating customer and restaurant-partner attrition. Fallout included mass user disengagement, sharp order decline, falling CSAT, restaurant-partner churn to competing platforms, and rising CAC. QuickBite has since committed a recovery budget, overhauled food-safety protocols, and upgraded delivery infra — this report tracks the crisis-phase impact (Jun–Sep) vs pre-crisis baseline (Jan–May).

 **Key Insights**

1. GMV and order volume moved in lockstep, down ~70% (Revenue: ₹37.6M→₹10.9M, -70.9% | Orders: 114K→35K, -68.9%) — confirms this was a demand-side trust collapse, not a pricing or supply issue.
2. The drop was a cliff, not a slope — orders fell 59% in a single month (May→June), timing directly matching the viral food-safety incident + delivery outage.
3. CSAT (avg rating) fell 44.5% (4.50→2.50) with the sentiment trendline inflecting right at crisis onset — sentiment led the user disengagement, not lagged it.
4. Active user base contracted 62.7% (87K→32K) — roughly 55K users disengaged, consistent with the "large portion of active users" pattern flagged in the crisis brief.
5. Delivery SLA is still broken, not just perception: delivery time +52.2% (39.5min→60.1min), SLA compliance -74.2% (47.4%→12.2%) — the outage damaged operational capability, and it hasn't recovered.
6. Cancel rate nearly doubled (6.1%→11.9%) and stayed elevated through Aug — direct downstream effect of the SLA breakdown, reinforcing the churn loop.
7. September shows a tentative inflection (Revenue +2%, Orders +2% MoM) — first positive movement post-crisis, but SLA and cancel rate haven't normalized, so it's not yet a confirmed recovery.

**Recommendations**

1. Conduct a root-cause SLA audit (city/partner-level) to isolate the delivery-outage aftershock still suppressing SLA%
2. Launch a segmented win-back campaign for the ~55K disengaged users, prioritized by pre-crisis LTV/order frequency
3. Set a phased SLA recovery target (e.g., 12.2% → 30% in 60 days) with delivery-partner accountability checkpoints
4. Break down cancellation reasons (late delivery vs stockout vs customer-initiated) to target fixes precisely
5. Audit restaurant-partner churn separately — verify whether food-safety protocol overhaul is being communicated to retain/re-onboard partners lost to competitors
6. Track CAC trend against the recovery budget spend to confirm reacquisition efficiency isn't worsening the cost problem
7. Monitor Sep's uptick on a weekly (not monthly) cadence before signaling recovery to stakeholders

An interactive Power BI Dashboard (as shown in the screenshots) can be downloaded [HERE].

The SQL Queries utilized for inspection and validation can be found [HERE].

SQL Queries used for cleaning and transformation can be found [HERE].

Targeted SQL Queries for deeper analysis can be found [HERE].

**Data Structure & Initial Checks** Quick Bites’ database structure, as illustrated in the model view, consists of 6 tables: Dim_Hotels, Fact_Bookings, Dim_Date, Dim_Rooms, Fact_Aggregated_Bookings, Dim_Customers, with a total row count of 508,627 records.

Executive Summary

Overview of Findings

![Dashboard](https://raw.githubusercontent.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/main/image/quick%20bites%20pbix%201.png)

QuickBite Express's crisis-period performance highlights a demand and trust breakdown that's directly threatening retention and unit economics. Total revenue stands at ₹10.94M, down 70.9% from the ₹37.62M pre-crisis baseline, while total orders fell to 35K, down 68.9% from 114K — showing that fewer customers are transacting, not just spending less per order. Active customers dropped to 32K, a 62.7% decline from 87K, indicating the crisis triggered mass disengagement rather than a temporary slowdown. Average rating fell to 2.50 from 4.50 (-44.5%), signaling that service quality and trust issues are driving this churn, not just external competition. Operationally, average delivery time rose to 60.11 minutes from 39.49 (+52.2%), and SLA compliance dropped sharply to 12.2% from 47.4% (-74.2%), pointing to a delivery-infrastructure failure as a root cause rather than a symptom. This operational breakdown is directly reflected in the cancel rate, which nearly doubled to 11.9% from 6.1% (+96.9%), showing customers are abandoning orders due to unreliable delivery promises. The monthly trend shows the collapse was sudden rather than gradual — orders fell 59% in a single month (May to June) — but September shows a small recovery signal, with revenue and orders both up 2% month-over-month, suggesting stabilization may be beginning. To recover, QuickBite should prioritize restoring SLA compliance and delivery speed first, since cancellations and ratings won't improve until delivery reliability is fixed, followed by a targeted win-back campaign for the 55K lost customers and continued monitoring of the September uptick before declaring recovery.

![Dashboard](https://raw.githubusercontent.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/main/image/quick%20bites%20pbix%201.png)

**City-Wise Performance**

- **Bengaluru and Mumbai are the biggest revenue-at-risk markets** — both lost ~70% of orders (Bengaluru: 31.3K→9.3K, Mumbai: 17.8K→5.3K) and saw cancellation spike >110%, the steepest CX degradation in the portfolio.
- **Delhi is the relative bright spot** — lowest cancellation increase (69.6% vs 90-116% elsewhere) despite a similar order drop (-69.8%), suggesting stronger ops resilience there.
- **Hyderabad and Chennai have a delivery-speed crisis, not a volume crisis** — highest delivery delays (~18 min) despite smaller order bases; this is dragging ratings down independently of demand loss.
- **Kolkata is the standout performer** — best pre-crisis and crisis performance index (0.23), and lowest cancellation among high-delay cities — worth benchmarking its ops playbook against Bengaluru/Mumbai.
- **Rating decline is uniform (~44%) across all cities** — this isn't a city-specific issue, it's systemic (points back to the food-safety/outage root cause, not local execution).
- **Key takeaway for PM:** Fix delivery SLA in Hyderabad/Chennai and cancellation control in Bengaluru/Mumbai first — these two levers cover the highest-revenue-impact markets.

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%203.png)

   **Restaurant-Level Impact**

- **Urban Kitchen Zone is the worst hit — order volume down 85.1%** (67→10), yet its sentiment drop (-133%) is mid-pack, suggesting delisting risk or partner-side supply issue rather than pure demand collapse — worth a partner-health check.
- **Flavours of Tandoor Central has the steepest rating decline (-50.2%)** paired with -84.4% order drop — this combo signals active customer avoidance, not just reduced discovery/traffic.
- **Hot & Crispy Kitchen Clouds shows the sharpest sentiment collapse (-141%)** despite a comparatively milder order drop (-54.0%) — sentiment is leading orders down here; expect further order erosion next cycle if unaddressed.
- **Sentiment decline (-109% to -153%) consistently outpaces rating decline (-36% to -51%)** across all 15 restaurants — sentiment score is capturing dissatisfaction (reviews/complaints) that star ratings alone understate; use sentiment as the earlier churn signal.
- **No restaurant in the top-15 improved on any metric** — this is portfolio-wide brand damage, not isolated bad actors; food-safety incident is likely suppressing trust at the platform level, not restaurant level.
- **PM action:** Segment these 15 into "recoverable" (moderate order drop + moderate sentiment) vs "at-risk" (Urban Kitchen Zone, Flavours of Tandoor Central) for differentiated win-back — blanket promos won't fix trust-driven churn.

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%204.png)

**Customer Behaviour & Loyalty**

- **Loyalty base collapsed harder than the overall user base** — only 37% of loyal customers retained (58→26), a steeper decline than the 62.7% overall churn rate. This is your highest-LTV segment eroding fastest — retention curve is inverted from what you'd want.
- **Low-value customer segment absorbed the heaviest churn** — dropped from 72K→25K (-65%), while Value-Sensitive (mid-spend) fell 12K→6K (-50%) and High-Value customers effectively hit zero. High-value cohort disappearing entirely is the most alarming AOV-mix signal here.
- **Mid-to-low value order mix shifted post-crisis** — Low-Value order share rose (46.0%→49.5%) while Mid-Value share fell (50.6%→47.3%), meaning surviving customers are trading down — basket-value compression compounding the volume loss.
- **New customer acquisition essentially flatlined** — repeat/new split stayed ~99.8% loyal-dominant pre-crisis, but from June onward "New" customers jumped to ~45-54% of the mix. This isn't organic growth — it reads as loyal-base replacement, not expansion, meaning CAC is being spent to backfill churn, not grow the funnel.
- **High-value order decline is cuisine-concentrated** — North Indian and Chinese categories show the steepest order drop-offs (up to -600 to -800% band) across nearly every city, especially Ahmedabad, Bengaluru, and Hyderabad — points to a specific category-level trust or quality issue, not a platform-wide uniform decline.
- **PM action:** Prioritize a loyalty win-back for the 32 lost loyal customers (58→26) with targeted incentives before broad-based reacquisition spend — reacquiring in this environment (2.50 avg rating, 12.2% SLA) risks high CAC with low retention payback until trust metrics recover.

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%205.png)

**Delivery Operations & SLA — Key Insights**

- **This is the smoking gun for the entire crisis** — SLA compliance cratered from 47%→12% in a single month (May→June: -89%), and it hasn't recovered in 4 months. This is the root-cause metric everything else (cancellations, ratings, churn) traces back to.
- **87.8% of all crisis-phase deliveries were late**, and 68% of those were late by 10+ minutes — this isn't marginal SLA slippage, it's systemic capacity failure (matches the outage narrative from the crisis brief).
- **Delay severity is compounding, not flat** — the 20+ min delay bucket (6.4K orders) is nearly 4x the 0-5 min bucket (1.7K), meaning most delayed orders aren't "slightly late," they're badly late — the worst-case bucket, not the edge case.
- **Delhi and Hyderabad have the highest order delay (~18 min)** — consistent with the City page finding, confirming these two markets need dedicated ops intervention, not portfolio-wide fixes.
- **SLA-Not-Met and Negative-Review% move together from June onward** (both jump to ~85-95%) — direct proof that delivery failure is driving review sentiment, not a coincidental overlap. This is your causal chain: SLA miss → negative review → rating drop → churn.
- **PM action:** Delivery capacity/partner-fleet expansion in Delhi and Hyderabad is the highest-leverage fix — SLA recovery here should be tracked as the #1 leading indicator for recovery, ahead of revenue or orders.

---

**Feedback & Sentiment Analysis**

- **Sentiment collapsed 133% faster than rating dropped 44.5%** (0.75→-0.25 vs 4.50→2.50) — sentiment (free-text reviews) is capturing dissatisfaction that the 5-star rating scale compresses/hides. Use sentiment score as the primary early-warning metric going forward, not star rating.
- **81% of reviews are now Negative** (only 15% Positive) — this is a near-total sentiment inversion from a presumably healthy pre-crisis mix, confirming brand trust damage is broad-based, not a vocal-minority effect.
- **"Terrible hygiene" reviews carry the worst score (-0.90 sentiment, 1.20 rating)** — hygiene/food-safety complaints are the most damaging review category, directly tied to the original viral incident — this is the #1 reputation risk to resolve publicly.

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%206.png)

**Delivery Operations & SLA — Key Insights**

- **This is the smoking gun for the entire crisis** — SLA compliance cratered from 47%→12% in a single month (May→June: -89%), and it hasn't recovered in 4 months. This is the root-cause metric everything else (cancellations, ratings, churn) traces back to.
- **87.8% of all crisis-phase deliveries were late**, and 68% of those were late by 10+ minutes — this isn't marginal SLA slippage, it's systemic capacity failure (matches the outage narrative from the crisis brief).
- **Delay severity is compounding, not flat** — the 20+ min delay bucket (6.4K orders) is nearly 4x the 0-5 min bucket (1.7K), meaning most delayed orders aren't "slightly late," they're badly late — the worst-case bucket, not the edge case.
- **Delhi and Hyderabad have the highest order delay (~18 min)** — consistent with the City page finding, confirming these two markets need dedicated ops intervention, not portfolio-wide fixes.
- **SLA-Not-Met and Negative-Review% move together from June onward** (both jump to ~85-95%) — direct proof that delivery failure is driving review sentiment, not a coincidental overlap. This is your causal chain: SLA miss → negative review → rating drop → churn.
- **PM action:** Delivery capacity/partner-fleet expansion in Delhi and Hyderabad is the highest-leverage fix — SLA recovery here should be tracked as the #1 leading indicator for recovery, ahead of revenue or orders.

---

**Feedback & Sentiment Analysis**

Sentiment collapsed 133% faster than rating dropped 44.5% (0.75→-0.25 vs 4.50→2.50) — sentiment (free-text reviews) is capturing dissatisfaction that the 5-star rating scale compresses/hides. Use sentiment score as the primary early-warning metric going forward, not star rating.
81% of reviews are now Negative (only 15% Positive) — this is a near-total sentiment inversion from a presumably healthy pre-crisis mix, confirming brand trust damage is broad-based, not a vocal-minority effect.
"Terrible hygiene" reviews carry the worst score (-0.90 sentiment, 1.20 rating) — hygiene/food-safety complaints are the most damaging review category, directly tied to the original viral incident — this is the #1 reputation risk to resolve publicly.
Sentiment kept falling even as rating stabilized slightly (June -0.21→Sept -0.35, while rating held ~2.3-2.7) — this divergence is a warning sign: customers who still rate moderately are writing increasingly negative reviews, suggesting frustration is deepening even among "tolerant" users.
Core complaint themes are hygiene, food safety, taste, and cold/stale food — these map directly to the food-safety root cause and delivery-delay root cause (cold food = late delivery), meaning both crisis triggers are still actively showing up in customer language 4 months later.
PM action: Prioritize a visible, communicated food-safety certification/audit rollout — sentiment won't recover from operational fixes alone; customers need proof of the hygiene fix, not just faster delivery.
