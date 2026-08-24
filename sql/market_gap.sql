-- Market Gap Analysis:

WITH metrics AS (
    SELECT 
        location_name,
        cafe AS competitors,
        restaurant + shopping_mall + office + park + tourist_attraction AS foot_traffic,
        
        (restaurant + shopping_mall + office + park + tourist_attraction)::numeric / 
            NULLIF((SELECT MAX(restaurant + shopping_mall + office + park + tourist_attraction) FROM mumbai_location_analysis), 0) 
            AS traffic_norm,
        
        (cafe::numeric) / 
            NULLIF((SELECT MAX(cafe) FROM mumbai_location_analysis), 0) 
            AS comp_norm
    FROM mumbai_location_analysis
),
opportunity_score AS (
    SELECT 
        location_name,
        competitors,
        foot_traffic,
        ROUND((traffic_norm * 0.7 - comp_norm * 0.3) * 100, 1) AS opportunity_score,
        ROUND(traffic_norm * 100, 1) AS traffic_percentile,
        ROUND(comp_norm * 100, 1) AS competitor_percentile
    FROM metrics
)
SELECT 
    location_name,
    foot_traffic,
    competitors,
    opportunity_score,
    traffic_percentile || '%' AS traffic_vs_others,
    competitor_percentile || '%' AS competition_vs_others,
    
    CASE 
        WHEN opportunity_score > 50 THEN 'Prime Opportunity'
        WHEN opportunity_score > 25 THEN 'Good Opportunity'
        WHEN opportunity_score > 0 THEN 'Moderate Opportunity'
        ELSE 'Saturated Market'
    END AS market_status
    
FROM opportunity_score
ORDER BY opportunity_score DESC;