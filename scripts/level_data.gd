extends Node

# Level configuration for 3 stages
# Lanes: 1 (Left = 145), 2 (Middle = 270), 3 (Right = 395)
# Types: "rock", "broken_car", "wrong_way"

static func get_stage_data(stage_num: int) -> Dictionary:
	var data = {
		"target_distance": 1000.0,
		"base_speed": 180.0,
		"max_speed": 280.0,
		"road_color": Color("2e3440"), # Grey slate
		"obstacles": []
	}
	
	match stage_num:
		1:
			data["target_distance"] = 800.0
			data["base_speed"] = 200.0
			data["max_speed"] = 300.0
			# Stage 1: Rocks only - Tutorial difficulty
			data["obstacles"] = [
				{"dist": 100.0, "lane": 1, "type": "rock"},
				{"dist": 150.0, "lane": 3, "type": "rock"},
				{"dist": 220.0, "lane": 2, "type": "rock"},
				{"dist": 280.0, "lane": 1, "type": "rock"},
				{"dist": 340.0, "lane": 3, "type": "rock"},
				{"dist": 400.0, "lane": 2, "type": "rock"},
				{"dist": 410.0, "lane": 1, "type": "rock"}, # Double rocks (left & mid)
				{"dist": 480.0, "lane": 3, "type": "rock"},
				{"dist": 540.0, "lane": 2, "type": "rock"},
				{"dist": 600.0, "lane": 1, "type": "rock"},
				{"dist": 610.0, "lane": 3, "type": "rock"},
				{"dist": 680.0, "lane": 2, "type": "rock"},
				{"dist": 720.0, "lane": 1, "type": "rock"},
				{"dist": 730.0, "lane": 3, "type": "rock"},
			]
		2:
			data["target_distance"] = 1200.0
			data["base_speed"] = 260.0
			data["max_speed"] = 380.0
			# Stage 2: Rocks & Broken Cars (lane blockades with warning flashing lights)
			data["obstacles"] = [
				{"dist": 120.0, "lane": 2, "type": "rock"},
				{"dist": 180.0, "lane": 1, "type": "broken_car"}, # Broken car in lane 1
				{"dist": 260.0, "lane": 3, "type": "rock"},
				{"dist": 320.0, "lane": 2, "type": "broken_car"},
				{"dist": 380.0, "lane": 1, "type": "rock"},
				{"dist": 390.0, "lane": 3, "type": "rock"},
				{"dist": 460.0, "lane": 3, "type": "broken_car"},
				{"dist": 520.0, "lane": 2, "type": "rock"},
				{"dist": 580.0, "lane": 1, "type": "broken_car"},
				{"dist": 640.0, "lane": 3, "type": "rock"},
				{"dist": 700.0, "lane": 2, "type": "broken_car"},
				{"dist": 760.0, "lane": 1, "type": "rock"},
				{"dist": 770.0, "lane": 3, "type": "rock"},
				{"dist": 850.0, "lane": 2, "type": "broken_car"},
				{"dist": 920.0, "lane": 1, "type": "rock"},
				{"dist": 980.0, "lane": 3, "type": "broken_car"},
				{"dist": 1050.0, "lane": 2, "type": "rock"},
			]
		3:
			data["target_distance"] = 1600.0
			data["base_speed"] = 340.0
			data["max_speed"] = 480.0
			# Stage 3: Extreme difficulty - Rocks, Broken Cars, and Wrong-way Drivers (speeding down, flashing alert)
			data["obstacles"] = [
				{"dist": 120.0, "lane": 1, "type": "rock"},
				{"dist": 180.0, "lane": 3, "type": "wrong_way"}, # Wrong way driver lane 3!
				{"dist": 260.0, "lane": 2, "type": "broken_car"},
				{"dist": 320.0, "lane": 1, "type": "wrong_way"},
				{"dist": 380.0, "lane": 3, "type": "rock"},
				{"dist": 440.0, "lane": 2, "type": "wrong_way"},
				{"dist": 500.0, "lane": 1, "type": "broken_car"},
				{"dist": 560.0, "lane": 3, "type": "wrong_way"},
				{"dist": 620.0, "lane": 2, "type": "rock"},
				{"dist": 680.0, "lane": 1, "type": "wrong_way"},
				{"dist": 690.0, "lane": 3, "type": "rock"},
				{"dist": 760.0, "lane": 2, "type": "broken_car"},
				{"dist": 820.0, "lane": 3, "type": "wrong_way"},
				{"dist": 880.0, "lane": 1, "type": "wrong_way"}, # Multi wrong way drivers
				{"dist": 940.0, "lane": 2, "type": "rock"},
				{"dist": 1000.0, "lane": 2, "type": "wrong_way"},
				{"dist": 1060.0, "lane": 3, "type": "broken_car"},
				{"dist": 1120.0, "lane": 1, "type": "wrong_way"},
				{"dist": 1200.0, "lane": 2, "type": "broken_car"},
				{"dist": 1260.0, "lane": 3, "type": "wrong_way"},
				{"dist": 1320.0, "lane": 1, "type": "rock"},
				{"dist": 1380.0, "lane": 2, "type": "wrong_way"},
				{"dist": 1440.0, "lane": 3, "type": "broken_car"},
			]
			
	return data
