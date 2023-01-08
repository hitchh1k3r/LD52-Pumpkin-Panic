package main

Action :: enum {
  None,
  Plant,
  Till,
  WaterCrop,
  Harvest,
  Water,
  FillWater,
  Harvest_Portal,
}

action_text := [Action]cstring {
  .None = "",
  .Plant = "Plant Pumpkin",
  .Till = "Till Land",
  .WaterCrop = "Water Pumpkin",
  .Harvest = "Harvest Pumpkin",
  .Water = "Water Pumpkin",
  .FillWater = "Gather Water",
  .Harvest_Portal = "Harvest",
}
