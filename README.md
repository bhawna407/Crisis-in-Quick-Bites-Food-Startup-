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
![Dashboard](https://raw.githubusercontent.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/main/image/quick%20bites%20pbix%201.png)

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%203.png)

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%204.png)

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%205.png)

![Dashboard](https://github.com/bhawna407/Crisis-in-Quick-Bites-Food-Startup-/blob/main/image/quick%20bites%20pbix%206.png)
