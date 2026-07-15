-- ============================================================================
-- QUICKBITE EXPRESS — CRISIS IN QUICK BITES
-- 01_data_cleaning_transformation.sql
-- Author: Bhawna Kaushik | Data Analyst
-- Purpose: Clean, standardize and transform raw QuickBite tables
--          (dim_customer, dim_delivery_partner, dim_menu_item, dim_restaurant,
--           fact_orders, fact_order_items, fact_delivery_performance, fact_ratings)
--          into analysis-ready tables/views.
-- Engine: MySQL 8.x
-- Assumption: Raw CSVs already loaded into tables of the SAME NAME via
--             LOAD DATA INFILE / Workbench Import Wizard, with all columns
--             imported as-is (dates/timestamps as VARCHAR/TEXT since source
--             files mix DD-MM-YYYY and YYYY-MM-DD formats).
-- ============================================================================

CREATE DATABASE IF NOT EXISTS quickbite_crisis;
USE quickbite_crisis;

-- ----------------------------------------------------------------------------
-- STEP 0: SANITY / PROFILING CHECKS (run before cleaning, keep for audit trail)
-- ----------------------------------------------------------------------------
SELECT 'fact_orders' AS tbl, COUNT(*) AS row_cnt FROM fact_orders
UNION ALL SELECT 'fact_order_items', COUNT(*) FROM fact_order_items
UNION ALL SELECT 'fact_delivery_performance', COUNT(*) FROM fact_delivery_performance
UNION ALL SELECT 'fact_ratings', COUNT(*) FROM fact_ratings
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_restaurant', COUNT(*) FROM dim_restaurant
UNION ALL SELECT 'dim_delivery_partner', COUNT(*) FROM dim_delivery_partner
UNION ALL SELECT 'dim_menu_item', COUNT(*) FROM dim_menu_item;

-- Check for duplicate order_ids (should be 0 in fact_orders)
SELECT order_id, COUNT(*) AS cnt
FROM fact_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check for fully-null / duplicate rows in fact_ratings (known data quality issue)
SELECT *
FROM fact_ratings
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR rating IS NULL;

SELECT order_id, customer_id, restaurant_id, rating, review_text, review_timestamp,
       COUNT(*) AS dup_cnt
FROM fact_ratings
GROUP BY order_id, customer_id, restaurant_id, rating, review_text, review_timestamp
HAVING COUNT(*) > 1;

-- Check NULLs in delivery_partner_id on fact_orders (expected: NULL only for cancelled orders)
SELECT is_cancelled, COUNT(*) AS orders,
       SUM(CASE WHEN delivery_partner_id IS NULL THEN 1 ELSE 0 END) AS null_partner_cnt
FROM fact_orders
GROUP BY is_cancelled;

-- ----------------------------------------------------------------------------
-- STEP 1: REMOVE BAD / EMPTY ROWS
-- ----------------------------------------------------------------------------
-- 17 fully-null trailing rows + 16 exact duplicates found in fact_ratings.

-- 1a. Drop rows where the core keys are NULL (garbage/blank rows at file end)
DELETE FROM fact_ratings
WHERE order_id IS NULL
   OR rating IS NULL;

-- 1b. Remove exact duplicate rating rows, keeping the lowest ctid/primary key.
--     MySQL 8 has no native ctid, so de-dup via a ranked CTE.
WITH ranked_ratings AS (
    SELECT
        order_id, customer_id, restaurant_id, rating, review_text,
        review_timestamp, sentiment_score,
        ROW_NUMBER() OVER (
            PARTITION BY order_id, customer_id, restaurant_id, rating,
                         review_text, review_timestamp
            ORDER BY order_id
        ) AS rn
    FROM fact_ratings
)
DELETE fr
FROM fact_ratings fr
JOIN (
    SELECT order_id, customer_id, restaurant_id, rating, review_text,
           review_timestamp,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, customer_id, restaurant_id, rating,
                            review_text, review_timestamp
               ORDER BY order_id
           ) AS rn
    FROM fact_ratings
) dupes
  ON fr.order_id = dupes.order_id
 AND fr.customer_id = dupes.customer_id
 AND fr.restaurant_id = dupes.restaurant_id
 AND fr.rating = dupes.rating
 AND fr.review_text = dupes.review_text
 AND fr.review_timestamp = dupes.review_timestamp
WHERE dupes.rn > 1;

-- ----------------------------------------------------------------------------
-- STEP 2: STANDARDIZE TEXT FIELDS (trim + consistent casing)
-- ----------------------------------------------------------------------------
UPDATE dim_customer         SET city = TRIM(city);
UPDATE dim_restaurant        SET city = TRIM(city), restaurant_name = TRIM(restaurant_name);
UPDATE dim_delivery_partner  SET city = TRIM(city), partner_name = TRIM(partner_name);
UPDATE dim_menu_item         SET item_name = TRIM(item_name), category = TRIM(category);

-- Standardize Y/N flags to boolean-friendly TINYINT columns (keeps source col intact)
ALTER TABLE fact_orders      ADD COLUMN is_cod_flag       TINYINT(1);
ALTER TABLE fact_orders      ADD COLUMN is_cancelled_flag TINYINT(1);
ALTER TABLE dim_restaurant   ADD COLUMN is_active_flag    TINYINT(1);
ALTER TABLE dim_delivery_partner ADD COLUMN is_active_flag TINYINT(1);
ALTER TABLE dim_menu_item    ADD COLUMN is_veg_flag       TINYINT(1);

UPDATE fact_orders SET is_cod_flag       = (UPPER(TRIM(is_cod)) = 'Y');
UPDATE fact_orders SET is_cancelled_flag = (UPPER(TRIM(is_cancelled)) = 'Y');
UPDATE dim_restaurant SET is_active_flag = (UPPER(TRIM(is_active)) = 'Y');
UPDATE dim_delivery_partner SET is_active_flag = (UPPER(TRIM(is_active)) = 'Y');
UPDATE dim_menu_item SET is_veg_flag = (UPPER(TRIM(is_veg)) = 'Y');

-- ----------------------------------------------------------------------------
-- STEP 3: FIX / STANDARDIZE DATE-TIME FORMATS
-- ----------------------------------------------------------------------------
-- fact_orders.order_timestamp        -> already 'YYYY-MM-DD HH:MM:SS'   -> cast directly
-- dim_customer.signup_date           -> 'DD-MM-YYYY'                    -> STR_TO_DATE
-- fact_ratings.review_timestamp      -> 'DD-MM-YYYY HH:MM'              -> STR_TO_DATE

ALTER TABLE fact_orders  ADD COLUMN order_datetime  DATETIME;
ALTER TABLE dim_customer ADD COLUMN signup_dt       DATE;
ALTER TABLE fact_ratings ADD COLUMN review_datetime DATETIME;

UPDATE fact_orders
SET order_datetime = STR_TO_DATE(order_timestamp, '%Y-%m-%d %H:%i:%s');

UPDATE dim_customer
SET signup_dt = STR_TO_DATE(signup_date, '%d-%m-%Y');

UPDATE fact_ratings
SET review_datetime = STR_TO_DATE(review_timestamp, '%d-%m-%Y %H:%i');

-- Sanity check: any rows that failed to parse (would show NULL after cast)?
SELECT COUNT(*) AS unparsed_orders   FROM fact_orders  WHERE order_datetime  IS NULL;
SELECT COUNT(*) AS unparsed_signups  FROM dim_customer WHERE signup_dt       IS NULL;
SELECT COUNT(*) AS unparsed_reviews  FROM fact_ratings WHERE review_datetime IS NULL;

-- ----------------------------------------------------------------------------
-- STEP 4: BUSINESS-LOGIC TRANSFORMATION — CRISIS TIMELINE FLAG
-- ----------------------------------------------------------------------------
-- Per problem statement: crisis began June 2025 (viral food-safety incident +
-- week-long delivery outage during monsoon). Dataset spans Jan–Sep 2025.
--   Pre-Crisis : Jan 2025 – May 2025
--   Crisis     : Jun 2025 – Sep 2025
-- (No recovery-phase months exist in this dataset; only two phases apply.)

ALTER TABLE fact_orders ADD COLUMN order_phase VARCHAR(20);

UPDATE fact_orders
SET order_phase = CASE
    WHEN order_datetime <  '2025-06-01' THEN 'Pre-Crisis'
    ELSE 'Crisis'
END;

ALTER TABLE fact_orders ADD COLUMN order_month VARCHAR(7);
UPDATE fact_orders SET order_month = DATE_FORMAT(order_datetime, '%Y-%m');

-- ----------------------------------------------------------------------------
-- STEP 5: HANDLE NULLS THAT ARE VALID BY DESIGN
-- ----------------------------------------------------------------------------
-- delivery_partner_id is NULL only for cancelled orders (verified in profiling).
-- We keep NULL as-is (do NOT impute) but add a readable label for reporting.
ALTER TABLE fact_orders ADD COLUMN delivery_partner_label VARCHAR(20);
UPDATE fact_orders
SET delivery_partner_label = CASE
    WHEN delivery_partner_id IS NULL THEN 'Not Assigned (Cancelled)'
    ELSE delivery_partner_id
END;

-- ----------------------------------------------------------------------------
-- STEP 6: DERIVED / TRANSFORMED METRICS
-- ----------------------------------------------------------------------------
-- 6a. Net revenue per order (subtotal - discount + delivery fee, cross-check vs total_amount)
ALTER TABLE fact_orders ADD COLUMN net_revenue DECIMAL(10,2);
UPDATE fact_orders
SET net_revenue = ROUND(subtotal_amount - discount_amount + delivery_fee, 2);

-- Flag mismatches between calculated net_revenue and stored total_amount (data QA)
SELECT order_id, subtotal_amount, discount_amount, delivery_fee, total_amount, net_revenue
FROM fact_orders
WHERE ABS(net_revenue - total_amount) > 0.5
LIMIT 100;

-- 6b. Delivery SLA breach flag (actual vs expected delivery time)
ALTER TABLE fact_delivery_performance ADD COLUMN sla_breached TINYINT(1);
UPDATE fact_delivery_performance
SET sla_breached = (actual_delivery_time_mins > expected_delivery_time_mins);

ALTER TABLE fact_delivery_performance ADD COLUMN delay_mins INT;
UPDATE fact_delivery_performance
SET delay_mins = actual_delivery_time_mins - expected_delivery_time_mins;

-- ----------------------------------------------------------------------------
-- STEP 7: INDEXING FOR ANALYSIS PERFORMANCE
-- ----------------------------------------------------------------------------
CREATE INDEX idx_orders_customer   ON fact_orders (customer_id);
CREATE INDEX idx_orders_restaurant ON fact_orders (restaurant_id);
CREATE INDEX idx_orders_phase      ON fact_orders (order_phase);
CREATE INDEX idx_orders_month      ON fact_orders (order_month);
CREATE INDEX idx_ratings_order     ON fact_ratings (order_id);
CREATE INDEX idx_orderitems_order  ON fact_order_items (order_id);
CREATE INDEX idx_delivery_order    ON fact_delivery_performance (order_id);

-- ----------------------------------------------------------------------------
-- STEP 8: ANALYSIS-READY VIEW — one row per order with all key dimensions joined
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_orders_enriched AS
SELECT
    o.order_id,
    o.customer_id,
    c.city                         AS customer_city,
    c.acquisition_channel,
    c.signup_dt,
    o.restaurant_id,
    r.restaurant_name,
    r.cuisine_type,
    r.partner_type,
    r.city                         AS restaurant_city,
    o.delivery_partner_id,
    o.order_datetime,
    o.order_month,
    o.order_phase,
    o.subtotal_amount,
    o.discount_amount,
    o.delivery_fee,
    o.total_amount,
    o.net_revenue,
    o.is_cod_flag,
    o.is_cancelled_flag,
    d.actual_delivery_time_mins,
    d.expected_delivery_time_mins,
    d.delay_mins,
    d.sla_breached,
    d.distance_km,
    rt.rating,
    rt.sentiment_score,
    rt.review_text
FROM fact_orders o
LEFT JOIN dim_customer   c  ON o.customer_id   = c.customer_id
LEFT JOIN dim_restaurant r  ON o.restaurant_id = r.restaurant_id
LEFT JOIN fact_delivery_performance d ON o.order_id = d.order_id
LEFT JOIN fact_ratings    rt ON o.order_id = rt.order_id;

-- Quick validation
SELECT order_phase, COUNT(*) AS orders FROM vw_orders_enriched GROUP BY order_phase;
