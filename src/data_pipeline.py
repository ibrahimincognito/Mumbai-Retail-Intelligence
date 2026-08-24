import requests
import pandas as pd
import time
from sqlalchemy import create_engine

# =====================================================
# YOUR FOURSQUARE API KEY
# =====================================================
FOURSQUARE_API_KEY = "3WNTKXRN2OF1PT5SCJKY2GSAKUFEXWIA1WXVPGUXFJGDYB1W"  # Your Service API Key

# =====================================================
# POSTGRESQL CONNECTION (port 5433)
# =====================================================
DB_PASSWORD = "IBK9211"

# =====================================================
# 30+ MUMBAI LOCATIONS
# =====================================================
locations = [
    {"name": "Colaba", "lat": 18.9130, "lng": 72.8172},
    {"name": "Fort", "lat": 18.9322, "lng": 72.8293},
    {"name": "Churchgate", "lat": 18.9350, "lng": 72.8268},
    {"name": "Marine Lines", "lat": 18.9460, "lng": 72.8230},
    {"name": "Dadar", "lat": 19.0161, "lng": 72.8487},
    {"name": "Lower Parel", "lat": 18.9939, "lng": 72.8255},
    {"name": "Bandra West", "lat": 19.0596, "lng": 72.8295},
    {"name": "Bandra Kurla Complex", "lat": 19.0636, "lng": 72.8681},
    {"name": "Andheri East", "lat": 19.1173, "lng": 72.8508},
    {"name": "Andheri West", "lat": 19.1275, "lng": 72.8120},
    {"name": "Juhu", "lat": 19.1026, "lng": 72.8260},
    {"name": "Powai", "lat": 19.1240, "lng": 72.9068},
    {"name": "Ghatkopar", "lat": 19.0860, "lng": 72.9100},
    {"name": "Malad", "lat": 19.1860, "lng": 72.8490},
    {"name": "Kandivali", "lat": 19.2060, "lng": 72.8500},
    {"name": "Goregaon", "lat": 19.1550, "lng": 72.8500},
    {"name": "Navi Mumbai (Vashi)", "lat": 19.0750, "lng": 73.0040},
    {"name": "Sion", "lat": 19.0400, "lng": 72.8600},
    {"name": "Matunga", "lat": 19.0190, "lng": 72.8440},
    {"name": "Versova", "lat": 19.1350, "lng": 72.8140},
    {"name": "Vikhroli", "lat": 19.1170, "lng": 72.9180},
]

# =====================================================
# CATEGORY MAPPING (Foursquare Category IDs)
# =====================================================
categories = {
    "restaurant": "4d4b7105d754a06374d81259",
    "cafe": "4bf58dd8d48988d16d941735",
    "bar": "4bf58dd8d48988d116941735",
    "bakery": "4bf58dd8d48988d16b941735",
    "meal_takeaway": "4bf58dd8d48988d1c5941735",
    "shopping_mall": "4bf58dd8d48988d1f5941735",
    "clothing_store": "4bf58dd8d48988d104951735",
    "supermarket": "4bf58dd8d48988d10a951735",
    "gym": "4bf58dd8d48988d175941735",
    "park": "4bf58dd8d48988d163941735",
    "library": "4bf58dd8d48988d12f941735",
    "museum": "4bf58dd8d48988d181941735",
    "tourist_attraction": "4bf58dd8d48988d1f2941735",
    "office": "4d4b7105d754a06376d81259",
    "bank": "4bf58dd8d48988d10f941735",
    "hospital": "4bf58dd8d48988d196941735",
    "school": "4bf58dd8d48988d13b941735",
    "university": "4bf58dd8d48988d1ae941735",
}

# =====================================================
# SEARCH VENUES FUNCTION (UPDATED)
# =====================================================
def search_venues(lat, lng, category_id, radius=500, limit=50):
    # --- NEW CORRECT ENDPOINT ---
    url = "https://places-api.foursquare.com/places/search"  # No /v3/ in the path[reference:2]
    
    headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {FOURSQUARE_API_KEY}",  # Service Key as Bearer token[reference:3]
        "X-Places-Api-Version": "2025-06-17"  # Required version header[reference:4]
    }
    
    params = {
        "ll": f"{lat},{lng}",
        "radius": radius,
        "categories": category_id,
        "limit": limit,
        "sort": "distance"
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = response.json()
        return data.get("results", [])
    except requests.exceptions.RequestException as e:
        print(f"   ⚠️ Error: {e}")
        return []

# =====================================================
# COLLECT DATA
# =====================================================
print("=" * 60)
print("🚀 STARTING FOURSQUARE DATA COLLECTION (NEW API)")
print(f"📍 Locations: {len(locations)}")
print(f"🏷️  Categories: {len(categories)}")
print("⏱️  Estimated time: ~5-7 minutes")
print("=" * 60)

all_counts = []
all_venues = []

for idx, loc in enumerate(locations):
    print(f"\n📍 Processing {loc['name']} ({idx+1}/{len(locations)})...")
    
    row = {"location_name": loc["name"], "latitude": loc["lat"], "longitude": loc["lng"]}
    
    for cat_name, cat_id in categories.items():
        venues = search_venues(loc["lat"], loc["lng"], cat_id)
        count = len(venues)
        row[cat_name] = count
        
        if cat_name == "cafe":
            for venue in venues:
                geocodes = venue.get("geocodes", {}).get("main", {})
                location = venue.get("location", {})
                stats = venue.get("stats", {})
                
                all_venues.append({
                    "name": venue.get("name", ""),
                    "address": location.get("formatted_address", ""),
                    "lat": geocodes.get("latitude", 0),
                    "lng": geocodes.get("longitude", 0),
                    "rating": venue.get("rating", None),
                    "reviews": stats.get("total_ratings", 0),
                    "location_name": loc["name"],
                    "fsq_id": venue.get("fsq_id", "")
                })
        
        print(f"   {cat_name}: {count}")
        time.sleep(0.15)
    
    all_counts.append(row)

print(f"\n✅ Collected counts for {len(all_counts)} locations")
print(f"✅ Collected {len(all_venues)} cafe competitors")

# =====================================================
# SAVE TO CSV
# =====================================================
df_counts = pd.DataFrame(all_counts)
df_venues = pd.DataFrame(all_venues)

df_counts.to_csv("location_counts_foursquare.csv", index=False)
df_venues.to_csv("competitors_foursquare.csv", index=False)

print("\n💾 Saved to CSV files:")
print(f"   - location_counts_foursquare.csv ({len(df_counts)} rows)")
print(f"   - competitors_foursquare.csv ({len(df_venues)} rows)")

# =====================================================
# LOAD TO POSTGRESQL
# =====================================================
try:
    connection_string = f"postgresql://postgres:{DB_PASSWORD}@localhost:5433/site_selection"
    engine = create_engine(connection_string)
    
    df_counts.to_sql("location_counts", engine, if_exists="replace", index=False)
    df_venues.to_sql("competitors", engine, if_exists="replace", index=False)
    
    print("\n✅ Data loaded into PostgreSQL (port 5433)")
    print(f"   - location_counts: {len(df_counts)} rows")
    print(f"   - competitors: {len(df_venues)} rows")
except Exception as e:
    print(f"\n❌ PostgreSQL connection error: {e}")
    print("   But CSV files are saved—import them manually if needed.")

print("\n" + "=" * 60)
print("🎉 DATA COLLECTION COMPLETE!")
print("=" * 60)