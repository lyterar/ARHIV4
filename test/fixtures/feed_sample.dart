/// Урезанный реальный ответ NASA NeoWs /feed за 2 дня (формат как у API).
const feedSample = '''
{
  "links": {"self": "https://api.nasa.gov/neo/rest/v1/feed?start_date=2026-11-23&end_date=2026-11-24"},
  "element_count": 3,
  "near_earth_objects": {
    "2026-11-24": [
      {
        "id": "3542519",
        "name": "(2010 PK9)",
        "estimated_diameter": {"meters": {"estimated_diameter_min": 115.4, "estimated_diameter_max": 258.1}},
        "is_potentially_hazardous_asteroid": true,
        "close_approach_data": [
          {
            "close_approach_date": "2026-11-24",
            "relative_velocity": {"kilometers_per_second": "18.1279360862"},
            "miss_distance": {"kilometers": "45290298.225725659"},
            "orbiting_body": "Earth"
          }
        ]
      },
      {
        "id": "2465633",
        "name": "465633 (2009 JR5)",
        "estimated_diameter": {"meters": {"estimated_diameter_min": 210.0, "estimated_diameter_max": 470.0}},
        "is_potentially_hazardous_asteroid": false,
        "close_approach_data": [
          {
            "close_approach_date": "2026-11-24",
            "relative_velocity": {"kilometers_per_second": "8.5"},
            "miss_distance": {"kilometers": "1200000.5"},
            "orbiting_body": "Earth"
          }
        ]
      }
    ],
    "2026-11-23": [
      {
        "id": "3726710",
        "name": "(2015 RC)",
        "estimated_diameter": {"meters": {"estimated_diameter_min": 24.0, "estimated_diameter_max": 54.0}},
        "is_potentially_hazardous_asteroid": false,
        "close_approach_data": [
          {
            "close_approach_date": "2026-11-23",
            "relative_velocity": {"kilometers_per_second": "19.4850295284"},
            "miss_distance": {"kilometers": "19781633.2" },
            "orbiting_body": "Earth"
          }
        ]
      }
    ]
  }
}
''';
