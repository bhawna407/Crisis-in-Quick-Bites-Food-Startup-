-- ============================================================================
-- QUICKBITE EXPRESS — CRISIS IN QUICK BITES
-- 02_analysis_queries.sql
-- Author: Bhawna Kaushik | Data Analyst
-- Purpose: Primary analysis — answers the 10 questions in
--          "Primary and Secondary Analysis.pdf" using the cleaned tables
--          and vw_orders_enriched view from 01_data_cleaning_transformation.sql
-- Engine: MySQL 8.x
-- Phase definition: Pre-Crisis = Jan–May 2025 | Crisis = Jun–Sep 2025
-- ============================================================================

USE quickbite_crisis;

-- ============================================================================
-- Q1. Monthly Orders: Pre-crisis (Jan–May) vs Crisis (Jun–Sep). How severe is the decline?
-- ============================================================================
-- 1a. Month-by-month order volume
SELECT
    order_month,
    order_phase,
    COUNT(*) AS total_orders
FROM fact_orders
GROUP BY order_month, order_phase
ORDER BY order_month;

-- 1b. Phase-level summary with % decline (avg monthly orders, since phases are unequal length)
WITH phase_summary AS (
    SELECT
        order_phase,
        COUNT(*) AS total_orders,
        COUNT(DISTINCT order_month) AS months_in_phase
    FROM fact_orders
    GROUP BY order_phase
)
SELECT
    order_phase,
    total_orders,
    months_in_phase,
    ROUND(total_orders / months_in_phase, 1) AS avg_monthly_orders,
    ROUND(
        (SELECT ROUND(total_orders / months_in_phase, 1) FROM phase_summary WHERE order_phase = 'Pre-Crisis')
        - AVG(total_orders / months_in_phase) OVER (), 1
    ) AS placeholder -- see 1c for clean % decline calc
FROM phase_summary;

-- 1c. Clean % decline in average monthly orders (Crisis vs Pre-Crisis)
SELECT
    pre.avg_monthly_orders  AS pre_crisis_avg_monthly_orders,
    cri.avg_monthly_orders  AS crisis_avg_monthly_orders,
    ROUND((cri.avg_monthly_orders - pre.avg_monthly_orders) / pre.avg_monthly_orders * 100, 2) AS pct_decline
FROM
    (SELECT ROUND(COUNT(*) / COUNT(DISTINCT order_month), 1) AS avg_monthly_orders
     FROM fact_orders WHERE order_phase = 'Pre-Crisis') pre,
    (SELECT ROUND(COUNT(*) / COUNT(DISTINCT order_month), 1) AS avg_monthly_orders
     FROM fact_orders WHERE order_phase = 'Crisis') cri;

-- ============================================================================
-- Q2. Top 5 city groups with the highest % decline in orders (crisis vs pre-crisis)
-- ============================================================================
WITH city_phase AS (
    SELECT
        c.city,
        o.order_phase,
        COUNT(*) AS total_orders,
        COUNT(DISTINCT o.order_month) AS months_in_phase
    FROM fact_orders o
    JOIN dim_customer c ON o.customer_id = c.customer_id
    GROUP BY c.city, o.order_phase
),
city_pivot AS (
    SELECT
        city,
        MAX(CASE WHEN order_phase = 'Pre-Crisis' THEN total_orders END) AS pre_crisis_orders,
        MAX(CASE WHEN order_phase = 'Pre-Crisis' THEN months_in_phase END) AS pre_months,
        MAX(CASE WHEN order_phase = 'Crisis'     THEN total_orders END) AS crisis_orders,
        MAX(CASE WHEN order_phase = 'Crisis'     THEN months_in_phase END) AS crisis_months
    FROM city_phase
    GROUP BY city
)
SELECT
    city,
    pre_crisis_orders,
    crisis_orders,
    ROUND(pre_crisis_orders / pre_months, 1) AS pre_crisis_avg_monthly,
    ROUND(crisis_orders / crisis_months, 1)  AS crisis_avg_monthly,
    ROUND(
        (ROUND(crisis_orders / crisis_months, 1) - ROUND(pre_crisis_orders / pre_months, 1))
        / ROUND(pre_crisis_orders / pre_months, 1) * 100, 2
    ) AS pct_decline
FROM city_pivot
ORDER BY pct_decline ASC   -- most negative = biggest decline
LIMIT 5;

-- ============================================================================
-- Q3. Top 10 high-volume restaurants (>=50 pre-crisis orders) with largest % decline
-- ============================================================================
WITH rest_phase AS (
    SELECT
        r.restaurant_id,
        r.restaurant_name,
        o.order_phase,
        COUNT(*) AS total_orders
    FROM fact_orders o
    JOIN dim_restaurant r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_id, r.restaurant_name, o.order_phase
),
rest_pivot AS (
    SELECT
        restaurant_id,
        restaurant_name,
        MAX(CASE WHEN order_phase = 'Pre-Crisis' THEN total_orders ELSE 0 END) AS pre_crisis_orders,
        MAX(CASE WHEN order_phase = 'Crisis'     THEN total_orders ELSE 0 END) AS crisis_orders
    FROM rest_phase
    GROUP BY restaurant_id, restaurant_name
)
SELECT
    restaurant_id,
    restaurant_name,
    pre_crisis_orders,
    crisis_orders,
    ROUND((crisis_orders - pre_crisis_orders) / pre_crisis_orders * 100, 2) AS pct_decline
FROM rest_pivot
WHERE pre_crisis_orders >= 50
ORDER BY pct_decline ASC
LIMIT 10;

-- ============================================================================
-- Q4. Cancellation Analysis: rate trend pre-crisis vs crisis, most affected cities
-- ============================================================================
-- 4a. Overall cancellation rate by phase
SELECT
    order_phase,
    COUNT(*) AS total_orders,
    SUM(is_cancelled_flag) AS cancelled_orders,
    ROUND(SUM(is_cancelled_flag) / COUNT(*) * 100, 2) AS cancellation_rate_pct
FROM fact_orders
GROUP BY order_phase;

-- 4b. Month-by-month cancellation rate trend
SELECT
    order_month,
    order_phase,
    COUNT(*) AS total_orders,
    SUM(is_cancelled_flag) AS cancelled_orders,
    ROUND(SUM(is_cancelled_flag) / COUNT(*) * 100, 2) AS cancellation_rate_pct
FROM fact_orders
GROUP BY order_month, order_phase
ORDER BY order_month;

-- 4c. Cities most affected by cancellations (based on restaurant city), crisis period
SELECT
    r.city,
    COUNT(*) AS total_orders,
    SUM(o.is_cancelled_flag) AS cancelled_orders,
    ROUND(SUM(o.is_cancelled_flag) / COUNT(*) * 100, 2) AS cancellation_rate_pct
FROM fact_orders o
JOIN dim_restaurant r ON o.restaurant_id = r.restaurant_id
WHERE o.order_phase = 'Crisis'
GROUP BY r.city
ORDER BY cancellation_rate_pct DESC;

-- ============================================================================
-- Q5. Delivery SLA: avg delivery time by phase, did SLA compliance worsen?
-- ============================================================================
SELECT
    o.order_phase,
    ROUND(AVG(d.actual_delivery_time_mins), 2)   AS avg_actual_delivery_mins,
    ROUND(AVG(d.expected_delivery_time_mins), 2) AS avg_expected_delivery_mins,
    ROUND(AVG(d.delay_mins), 2)                  AS avg_delay_mins,
    COUNT(*) AS total_deliveries,
    SUM(d.sla_breached) AS sla_breached_cnt,
    ROUND(SUM(d.sla_breached) / COUNT(*) * 100, 2) AS sla_breach_rate_pct
FROM fact_orders o
JOIN fact_delivery_performance d ON o.order_id = d.order_id
GROUP BY o.order_phase;

-- Month-level SLA trend (to pinpoint the outage week/month)
SELECT
    o.order_month,
    ROUND(AVG(d.actual_delivery_time_mins), 2) AS avg_actual_delivery_mins,
    ROUND(SUM(d.sla_breached) / COUNT(*) * 100, 2) AS sla_breach_rate_pct
FROM fact_orders o
JOIN fact_delivery_performance d ON o.order_id = d.order_id
GROUP BY o.order_month
ORDER BY o.order_month;

-- ============================================================================
-- Q6. Ratings Fluctuation: avg rating month-by-month, sharpest drop
-- ============================================================================
SELECT
    o.order_month,
    o.order_phase,
    ROUND(AVG(rt.rating), 2) AS avg_rating,
    COUNT(rt.rating) AS ratings_count
FROM fact_orders o
JOIN fact_ratings rt ON o.order_id = rt.order_id
GROUP BY o.order_month, o.order_phase
ORDER BY o.order_month;

-- Month-over-month change in avg rating (to flag sharpest drop)
WITH monthly_rating AS (
    SELECT
        o.order_month,
        ROUND(AVG(rt.rating), 2) AS avg_rating
    FROM fact_orders o
    JOIN fact_ratings rt ON o.order_id = rt.order_id
    GROUP BY o.order_month
)
SELECT
    order_month,
    avg_rating,
    LAG(avg_rating) OVER (ORDER BY order_month) AS prev_month_rating,
    ROUND(avg_rating - LAG(avg_rating) OVER (ORDER BY order_month), 2) AS mom_change
FROM monthly_rating
ORDER BY order_month;

-- ============================================================================
-- Q7. Sentiment Insights: most frequent negative keywords during crisis
-- (SQL can surface low-rating/negative-sentiment reviews for word-cloud input
--  in Power BI; true tokenization/word-cloud is best done in Power BI or Python.)
-- ============================================================================
-- 7a. Pull raw negative review text (crisis period) for word-cloud visual in Power BI
SELECT
    o.order_id,
    o.order_month,
    rt.rating,
    rt.sentiment_score,
    rt.review_text
FROM fact_orders o
JOIN fact_ratings rt ON o.order_id = rt.order_id
WHERE o.order_phase = 'Crisis'
  AND (rt.rating <= 2.5 OR rt.sentiment_score < 0)
ORDER BY rt.sentiment_score ASC;

-- 7b. Basic single-word frequency count (approximation; use only for common single
--     keywords — for full phrase-level word cloud, export 7a into Power BI/Python)
-- Requires a numbers/tally table; simplified version using common negative terms:
SELECT
    keyword,
    COUNT(*) AS mentions
FROM (
    SELECT o.order_id,
        CASE WHEN rt.review_text LIKE '%late%'        THEN 'late'        END AS keyword
    FROM fact_orders o JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Crisis'
    UNION ALL
    SELECT o.order_id,
        CASE WHEN rt.review_text LIKE '%cold%'         THEN 'cold'        END
    FROM fact_orders o JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Crisis'
    UNION ALL
    SELECT o.order_id,
        CASE WHEN rt.review_text LIKE '%cancel%'       THEN 'cancel'      END
    FROM fact_orders o JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Crisis'
    UNION ALL
    SELECT o.order_id,
        CASE WHEN rt.review_text LIKE '%hygiene%' OR rt.review_text LIKE '%safety%' THEN 'hygiene/safety' END
    FROM fact_orders o JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Crisis'
    UNION ALL
    SELECT o.order_id,
        CASE WHEN rt.review_text LIKE '%rude%'         THEN 'rude'        END
    FROM fact_orders o JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Crisis'
) kw
WHERE keyword IS NOT NULL
GROUP BY keyword
ORDER BY mentions DESC;
-- NOTE: Adjust the keyword list above after eyeballing 7a's raw text output —
-- this is a starting point, not exhaustive. Word Cloud visual in Power BI on
-- the raw review_text (7a) will give a more complete picture.

-- ============================================================================
-- Q8. Revenue Impact: revenue loss pre-crisis vs crisis (subtotal, discount, delivery fee)
-- ============================================================================
SELECT
    order_phase,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_month) AS months_in_phase,
    ROUND(SUM(subtotal_amount), 2)  AS total_subtotal,
    ROUND(SUM(discount_amount), 2)  AS total_discount,
    ROUND(SUM(delivery_fee), 2)     AS total_delivery_fee,
    ROUND(SUM(net_revenue), 2)      AS total_net_revenue,
    ROUND(SUM(net_revenue) / COUNT(DISTINCT order_month), 2) AS avg_monthly_net_revenue
FROM fact_orders
WHERE is_cancelled_flag = 0        -- exclude cancelled orders from revenue realized
GROUP BY order_phase;

-- Estimated revenue loss: (pre-crisis avg monthly revenue - crisis avg monthly revenue) x crisis months
WITH phase_rev AS (
    SELECT
        order_phase,
        ROUND(SUM(net_revenue) / COUNT(DISTINCT order_month), 2) AS avg_monthly_net_revenue,
        COUNT(DISTINCT order_month) AS months_in_phase
    FROM fact_orders
    WHERE is_cancelled_flag = 0
    GROUP BY order_phase
)
SELECT
    pre.avg_monthly_net_revenue AS pre_crisis_avg_monthly_revenue,
    cri.avg_monthly_net_revenue AS crisis_avg_monthly_revenue,
    cri.months_in_phase AS crisis_months,
    ROUND((pre.avg_monthly_net_revenue - cri.avg_monthly_net_revenue) * cri.months_in_phase, 2) AS estimated_total_revenue_loss
FROM
    (SELECT * FROM phase_rev WHERE order_phase = 'Pre-Crisis') pre,
    (SELECT * FROM phase_rev WHERE order_phase = 'Crisis') cri;

-- ============================================================================
-- Q9. Loyalty Impact: customers with >=5 pre-crisis orders who stopped ordering
--     during crisis, and how many of those had avg rating > 4.5
-- ============================================================================
WITH pre_crisis_loyal AS (
    SELECT
        customer_id,
        COUNT(*) AS pre_crisis_orders
    FROM fact_orders
    WHERE order_phase = 'Pre-Crisis'
    GROUP BY customer_id
    HAVING COUNT(*) >= 5
),
crisis_activity AS (
    SELECT DISTINCT customer_id
    FROM fact_orders
    WHERE order_phase = 'Crisis'
),
churned_loyal AS (
    SELECT p.customer_id, p.pre_crisis_orders
    FROM pre_crisis_loyal p
    LEFT JOIN crisis_activity c ON p.customer_id = c.customer_id
    WHERE c.customer_id IS NULL
),
churned_loyal_rating AS (
    SELECT
        cl.customer_id,
        cl.pre_crisis_orders,
        ROUND(AVG(rt.rating), 2) AS avg_rating_pre_crisis
    FROM churned_loyal cl
    JOIN fact_orders o ON cl.customer_id = o.customer_id AND o.order_phase = 'Pre-Crisis'
    JOIN fact_ratings rt ON o.order_id = rt.order_id
    GROUP BY cl.customer_id, cl.pre_crisis_orders
)
SELECT
    (SELECT COUNT(*) FROM pre_crisis_loyal)        AS total_loyal_customers,
    (SELECT COUNT(*) FROM churned_loyal)            AS churned_loyal_customers,
    (SELECT COUNT(*) FROM churned_loyal_rating WHERE avg_rating_pre_crisis > 4.5) AS churned_and_highly_rated;

-- Detail-level list (for drill-through in Power BI)
SELECT
    cl.customer_id,
    cl.pre_crisis_orders,
    ROUND(AVG(rt.rating), 2) AS avg_rating_pre_crisis
FROM (
    SELECT p.customer_id, p.pre_crisis_orders
    FROM (
        SELECT customer_id, COUNT(*) AS pre_crisis_orders
        FROM fact_orders
        WHERE order_phase = 'Pre-Crisis'
        GROUP BY customer_id
        HAVING COUNT(*) >= 5
    ) p
    LEFT JOIN (
        SELECT DISTINCT customer_id FROM fact_orders WHERE order_phase = 'Crisis'
    ) c ON p.customer_id = c.customer_id
    WHERE c.customer_id IS NULL
) cl
JOIN fact_orders o ON cl.customer_id = o.customer_id AND o.order_phase = 'Pre-Crisis'
JOIN fact_ratings rt ON o.order_id = rt.order_id
GROUP BY cl.customer_id, cl.pre_crisis_orders
ORDER BY avg_rating_pre_crisis DESC;

-- ============================================================================
-- Q10. Customer Lifetime Decline: top 5% customers by pre-crisis spend —
--      drop in order frequency & ratings during crisis + shared patterns
-- ============================================================================
WITH pre_crisis_spend AS (
    SELECT
        customer_id,
        SUM(net_revenue) AS pre_crisis_spend,
        COUNT(*) AS pre_crisis_orders
    FROM fact_orders
    WHERE order_phase = 'Pre-Crisis' AND is_cancelled_flag = 0
    GROUP BY customer_id
),
spend_ranked AS (
    SELECT
        customer_id,
        pre_crisis_spend,
        pre_crisis_orders,
        PERCENT_RANK() OVER (ORDER BY pre_crisis_spend DESC) AS pct_rank
    FROM pre_crisis_spend
),
top5pct_customers AS (
    SELECT customer_id, pre_crisis_spend, pre_crisis_orders
    FROM spend_ranked
    WHERE pct_rank <= 0.05
),
crisis_activity AS (
    SELECT
        customer_id,
        COUNT(*) AS crisis_orders
    FROM fact_orders
    WHERE order_phase = 'Crisis' AND is_cancelled_flag = 0
    GROUP BY customer_id
),
pre_rating AS (
    SELECT o.customer_id, ROUND(AVG(rt.rating), 2) AS pre_crisis_avg_rating
    FROM fact_orders o
    JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Pre-Crisis'
    GROUP BY o.customer_id
),
crisis_rating AS (
    SELECT o.customer_id, ROUND(AVG(rt.rating), 2) AS crisis_avg_rating
    FROM fact_orders o
    JOIN fact_ratings rt ON o.order_id = rt.order_id
    WHERE o.order_phase = 'Crisis'
    GROUP BY o.customer_id
)
SELECT
    t.customer_id,
    c.city AS customer_city,
    c.acquisition_channel,
    t.pre_crisis_spend,
    t.pre_crisis_orders,
    COALESCE(ca.crisis_orders, 0) AS crisis_orders,
    ROUND((COALESCE(ca.crisis_orders, 0) - t.pre_crisis_orders) / t.pre_crisis_orders * 100, 2) AS order_freq_pct_change,
    pr.pre_crisis_avg_rating,
    cr.crisis_avg_rating,
    ROUND(COALESCE(cr.crisis_avg_rating, 0) - COALESCE(pr.pre_crisis_avg_rating, 0), 2) AS rating_change
FROM top5pct_customers t
JOIN dim_customer c ON t.customer_id = c.customer_id
LEFT JOIN crisis_activity ca ON t.customer_id = ca.customer_id
LEFT JOIN pre_rating pr ON t.customer_id = pr.customer_id
LEFT JOIN crisis_rating cr ON t.customer_id = cr.customer_id
ORDER BY order_freq_pct_change ASC;

-- 10b. Shared-pattern lens for the same top-5% cohort: city, cuisine preference, delivery delay
WITH pre_crisis_spend AS (
    SELECT customer_id, SUM(net_revenue) AS pre_crisis_spend
    FROM fact_orders
    WHERE order_phase = 'Pre-Crisis' AND is_cancelled_flag = 0
    GROUP BY customer_id
),
top5pct_customers AS (
    SELECT customer_id
    FROM (
        SELECT customer_id, PERCENT_RANK() OVER (ORDER BY pre_crisis_spend DESC) AS pct_rank
        FROM pre_crisis_spend
    ) r
    WHERE pct_rank <= 0.05
)
SELECT
    c.city AS customer_city,
    r.cuisine_type AS preferred_cuisine,
    ROUND(AVG(d.delay_mins), 2) AS avg_delivery_delay_mins,
    COUNT(*) AS order_cnt
FROM fact_orders o
JOIN top5pct_customers t ON o.customer_id = t.customer_id
JOIN dim_customer c ON o.customer_id = c.customer_id
JOIN dim_restaurant r ON o.restaurant_id = r.restaurant_id
LEFT JOIN fact_delivery_performance d ON o.order_id = d.order_id
WHERE o.order_phase = 'Crisis'
GROUP BY c.city, r.cuisine_type
ORDER BY order_cnt DESC;
