
# 🏃‍♂️ Ultramarathon Performance Analytics

This project analyzes ultramarathon performance trends for Western States 100 and UTMB Finals qualifiers. It explores race outcomes, environmental factors, and gender competitiveness using data from UltraSignup, UTMB World Series, and weather APIs.

---

## 🎯 Objectives
- Analyze performance outcomes of Golden Ticket and UTMB World Series qualifiers.
- Identify which races yield the strongest or most consistent results.
- Explore how temperature, elevation, and terrain impact finishing times and DNF rates.
- Examine gender distribution and competitiveness across events.

---

## 📊 Data Sources
- 

---

## 🧰 Current Progress
- 

---

## 🧪 Planned Features
- 

---

## 🗄 Database Schema
```mermaid
erDiagram
    race_id_master {
        int race_id PK
        string race_name
        string series_id
        date race_date
        string race_loc
        float race_dist
    }

    course_details {
        int race_id FK
        float norm_difficulty_index
        float difficulty_index
        float distance_mi
        float elevation_gain_ft
        float elevation_loss_ft
        float max_elev_ft
        float min_elev_ft
        float elevation_range_ft
        float avg_grade_pct
        float altitude_exposure_mi
        int num_aid_stations
        string course_type
        float long_dist_to_aid
        float latitude
        float longitude
    }

    weather_conditions {
        int race_id FK
        date race_date
        float heat_index
        float wind_speed
        float precipitation
        float cloud_cover
        float temp_max
        float temp_min
        float humidity
        float dew_point
        float dew_point_comfort
        string conditions
    }

    golden_ticket_races {
        int race_id FK
        int ws_id FK
        int ws_year
        int ticket_position
        string gender
        string name
        boolean golden_ticket
    }

    western_states_results {
        int race_id PK
        string series_id
        date race_date
        int year
        int rank
        string status
        string name
        string nationality
        string gender
        int gender_rank
        string age_category
        string time
        string race_name
        string race_loc
        float race_dist
    }

    name_mapping {
        string alias_name
        string normalized_name
    }

    race_id_master ||--o{ course_details : "has"
    race_id_master ||--o{ weather_conditions : "has"
    race_id_master ||--o{ golden_ticket_races : "has"
    western_states_results ||--o{ golden_ticket_races : "linked to"
    golden_ticket_races }o--|| name_mapping : "normalizes"

