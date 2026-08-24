-- Competitor Density Analysis:

WITH density_analysis AS (
    SELECT 
        location_name,
        cafe AS competitor_count,
        restaurant + shopping_mall + office + park AS foot_traffic_composite,
        
        CASE 
            WHEN cafe >= 35 THEN 'Extremely Saturated'
            WHEN cafe >= 25 THEN 'Highly Competitive'
            WHEN cafe >= 15 THEN 'Moderately Competitive'
            WHEN cafe >= 5 THEN 'Low Competition'
            ELSE 'Virgin Territory'
        END AS competitor_density,
        
        CASE 
            WHEN restaurant + shopping_mall + office + park >= 150 THEN 'High Foot Traffic'
            WHEN restaurant + shopping_mall + office + park >= 100 THEN 'Medium Foot Traffic'
            ELSE 'Low Foot Traffic'
        END AS foot_traffic_level
        
    FROM mumbai_location_analysis
)
SELECT 
    location_name,
    competitor_count,
    foot_traffic_composite,
    competitor_density,
    foot_traffic_level,
    
    CASE 
        WHEN competitor_density IN ('Low Competition', 'Virgin Territory') 
             AND foot_traffic_level = 'High Foot Traffic' 
             THEN 'Strongly Recommended'
        
        WHEN competitor_density = 'Moderately Competitive' 
             AND foot_traffic_level IN ('High Foot Traffic', 'Medium Foot Traffic') 
             THEN 'Consider'
        
        WHEN competitor_density IN ('Extremely Saturated', 'Highly Competitive') 
             THEN 'Avoid'
        
        ELSE 'Further Analysis Needed'
    END AS site_recommendation
    
FROM density_analysis
ORDER BY competitor_count ASC, foot_traffic_composite DESC;
