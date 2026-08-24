-- Weighted Location Scores:

WITH location_scores AS (
    SELECT 
        location_name,
        latitude,
        longitude,
        (restaurant * 0.8 + shopping_mall * 0.7 + office * 0.6 + 
         park * 0.5 + gym * 0.4 + tourist_attraction * 0.6 + 
         bank * 0.3 + hospital * 0.3 + school * 0.3) 
        - (cafe * 0.8 + bar * 0.3) AS weighted_score,
        
        restaurant + shopping_mall + office + park + tourist_attraction AS foot_traffic_score,
        cafe AS competitor_count
        
    FROM mumbai_location_analysis
)
SELECT 
    location_name,
    ROUND(weighted_score::numeric, 2) AS location_score,
    foot_traffic_score,
    competitor_count,
    ROUND((foot_traffic_score::numeric / NULLIF(competitor_count + 1, 0)), 2) AS market_gap_ratio,
    
    CASE 
        WHEN weighted_score > 50 THEN 'High Potential'
        WHEN weighted_score > 30 THEN 'Medium Potential'
        WHEN weighted_score > 10 THEN 'Low Potential'
        ELSE 'Not Recommended'
    END AS recommendation
    
FROM location_scores
ORDER BY weighted_score DESC;