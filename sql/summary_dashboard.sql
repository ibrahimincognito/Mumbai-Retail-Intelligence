-- Summary Dashboard:

WITH base AS (
    SELECT 
        location_name,
        cafe,
        restaurant,
        shopping_mall,
        office,
        park,
        gym,
        tourist_attraction,
        bank,
        hospital,
        school,
        
        (restaurant * 0.8 + shopping_mall * 0.7 + office * 0.6 + 
         park * 0.5 + gym * 0.4 + tourist_attraction * 0.6 + 
         bank * 0.3 + hospital * 0.3 + school * 0.3) 
        - (cafe * 0.8) AS weighted_score
    FROM mumbai_location_analysis
),
ranked AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY weighted_score DESC) AS rank
    FROM base
),
aggregated AS (
    SELECT 
        ROUND(AVG(cafe)::numeric, 1) AS avg_cafes,
        ROUND(AVG(restaurant)::numeric, 1) AS avg_restaurants,
        ROUND(AVG(shopping_mall)::numeric, 1) AS avg_malls,
        MAX(cafe) AS max_cafes,
        MIN(cafe) AS min_cafes
    FROM mumbai_location_analysis
)
SELECT 
    r.location_name,
    r.cafe AS cafe_count,
    r.restaurant AS restaurant_count,
    r.shopping_mall AS mall_count,
    r.office AS office_count,
    r.park AS park_count,
    ROUND(r.weighted_score::numeric, 2) AS weighted_score,
    r.rank,
    
    ROUND((r.cafe::numeric / NULLIF(a.avg_cafes, 0)) * 100, 1) || '%' AS cafes_vs_avg,
    ROUND((r.restaurant::numeric / NULLIF(a.avg_restaurants, 0)) * 100, 1) || '%' AS restaurants_vs_avg,
    
    CASE 
        WHEN r.rank <= 3 THEN 'Top Tier'
        WHEN r.rank <= 7 THEN 'Second Tier'
        ELSE 'Opportunity Area'
    END AS tier
    
FROM ranked r
CROSS JOIN aggregated a
ORDER BY r.rank;