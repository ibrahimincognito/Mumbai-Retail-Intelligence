-- Locations Rank:

WITH location_scores AS (
    SELECT 
        location_name,
        (restaurant * 0.8 + shopping_mall * 0.7 + office * 0.6 + 
         park * 0.5 + gym * 0.4 + tourist_attraction * 0.6 + 
         bank * 0.3 + hospital * 0.3 + school * 0.3) 
        - (cafe * 0.8 + bar * 0.3) AS weighted_score,
        
        cafe AS competitor_count,
        restaurant + shopping_mall + office + park + tourist_attraction AS foot_traffic_score
        
    FROM mumbai_location_analysis
),
ranked AS (
    SELECT 
        location_name,
        ROUND(weighted_score::numeric, 2) AS score,
        foot_traffic_score,
        competitor_count,
        RANK() OVER (ORDER BY weighted_score DESC) AS location_rank,
        DENSE_RANK() OVER (ORDER BY weighted_score DESC) AS dense_rank,
        -- FIX: Cast PERCENT_RANK() to numeric before rounding
        ROUND((PERCENT_RANK() OVER (ORDER BY weighted_score DESC))::numeric * 100, 1) AS percentile_rank,
        
        CASE 
            WHEN RANK() OVER (ORDER BY weighted_score DESC) <= 3 THEN 'Top Tier'
            WHEN RANK() OVER (ORDER BY weighted_score DESC) <= 5 THEN 'Second Tier'
            ELSE 'Other'
        END AS tier
    FROM location_scores
)
SELECT 
    location_name,
    score,
    foot_traffic_score,
    competitor_count,
    location_rank,
    percentile_rank || '%' AS percentile,
    tier
FROM ranked
ORDER BY location_rank;