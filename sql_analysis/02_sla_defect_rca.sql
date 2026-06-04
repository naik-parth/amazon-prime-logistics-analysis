-- Prime Fulfillment SLA Defect Analysis (Pivoting & Timestamp Deltas)
UNLOAD ('
    WITH OrderTimestamps AS (
        SELECT 
            o.order_id,
            o.is_prime,
            t.fc_id,
            t.carrier_id,
            MAX(CASE WHEN t.event_status = ''Order Placed'' THEN t.event_timestamp END) AS time_placed,
            MAX(CASE WHEN t.event_status = ''Inventory Picked'' THEN t.event_timestamp END) AS time_picked,
            MAX(CASE WHEN t.event_status = ''Order Packed'' THEN t.event_timestamp END) AS time_packed,
            MAX(CASE WHEN t.event_status = ''Handed to Carrier'' THEN t.event_timestamp END) AS time_shipped,
            MAX(CASE WHEN t.event_status = ''Delivered'' THEN t.event_timestamp END) AS time_delivered,
            MAX(CASE WHEN t.event_status = ''Lost in Transit'' THEN t.event_timestamp END) AS time_lost
        FROM fact_orders o
        JOIN fact_tracking_logs t ON o.order_id = t.order_id
        GROUP BY 1, 2, 3, 4
    ),
    Durations AS (
        SELECT 
            order_id,
            is_prime,
            fc_id,
            carrier_id,
            EXTRACT(EPOCH FROM (time_picked - time_placed))/3600.0 AS hrs_to_pick,
            EXTRACT(EPOCH FROM (time_packed - time_picked))/3600.0 AS hrs_to_pack,
            EXTRACT(EPOCH FROM (time_delivered - time_shipped))/3600.0 AS hrs_in_transit,
            EXTRACT(EPOCH FROM (COALESCE(time_delivered, time_lost) - time_placed))/3600.0 AS hrs_total_lifecycle,
            CASE WHEN time_lost IS NOT NULL THEN 1 ELSE 0 END AS is_lost
        FROM OrderTimestamps
    ),
    SLA_Analysis AS (
        SELECT 
            *,
            CASE 
                WHEN is_prime AND hrs_total_lifecycle > 48.0 THEN 1 
                WHEN is_prime AND is_lost = 1 THEN 1
                ELSE 0 
            END AS prime_sla_defect
        FROM Durations
        WHERE is_prime = TRUE
    )
    SELECT 
        fc_id,
        carrier_id,
        COUNT(order_id) AS total_prime_orders,
        ROUND(AVG(hrs_to_pick), 2) AS avg_pick_hours,
        ROUND(AVG(hrs_to_pack), 2) AS avg_pack_hours,
        ROUND(AVG(hrs_in_transit), 2) AS avg_transit_hours,
        SUM(prime_sla_defect) AS total_defects,
        ROUND(SUM(prime_sla_defect)::DECIMAL / COUNT(order_id) * 100, 2) AS defect_rate_pct
    FROM SLA_Analysis
    GROUP BY fc_id, carrier_id
    ORDER BY defect_rate_pct DESC;
')
TO 's3://amazon-supply-chain-portfolio-data/amazon_sla_results_'
IAM_ROLE 'arn:aws:iam::[ACCOUNT_ID]:role/[ROLE_NAME]'
CSV HEADER PARALLEL OFF;