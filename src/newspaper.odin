package main

import "core:math/rand"
import "core:slice"

Headline :: enum {
  Intro,

  New_Farm,

  Good_Weather,
  Trick_Or_Treat,
  Farmers_Market,
  Haunted_Happenings,
  Work_Day,

  Ghost_Spotted,

  Largest_Pumpkin,
  Fundraiser,
  Popular_1,
  Unique_Experiance,
  Popular_2,

  Missing_Persons,

  Bad_1,
  Bad_2,
  Bad_3,
  Bad_4,
  Bad_5,

  Portal,

  Portal_1,
  Portal_2,
  Portal_3,
}

StoryProgress :: enum {
  Start, // automatic
    Halloween,
  Ghost_Spotted, // has all basic locations
    Haunted,
  Missing_Persons, // has bought one "secret soil"
    Bad_Stuff,
  Portal, // has 1000 pumpkins in bank when opening paper
    Post_Portal,
}

story_progress := StoryProgress.Start

headline_pool := [StoryProgress][]Headline {
  .Start = {
    .New_Farm,
  },

  .Halloween = {
    .Good_Weather,
    .Trick_Or_Treat,
    .Farmers_Market,
    .Haunted_Happenings,
    .Work_Day,
  },

  .Ghost_Spotted = {
    .Ghost_Spotted,
  },

  .Haunted = {
    .Largest_Pumpkin,
    .Fundraiser,
    .Popular_1,
    .Unique_Experiance,
    .Popular_2,
  },

  .Missing_Persons = {
    .Missing_Persons,
  },

  .Bad_Stuff = {
    .Bad_1,
    .Bad_2,
    .Bad_3,
    .Bad_4,
    .Bad_5,
  },

  .Portal = {
    .Portal,
  },

  .Post_Portal = {
    .Portal_1,
    .Portal_2,
    .Portal_3,
  },
}

ClassifiedAd :: struct {
  available : bool,
  title : cstring,
  body : cstring,
  cost : int,
  user_data : int,
  callback : #type proc(user_data : int),
}

@(private="file") classified_add_idx := 0

clear_classifieds :: proc() {
  for i in 0..<len(classifieds) {
    classifieds[i].available = false
  }
  classified_add_idx = 0
}

add_classified_region :: proc(region : MapRegion) {
  if region not_in regions_gotten {
    classifieds[classified_add_idx] = get_region_ad(region)
    classified_add_idx += 1
  }
}

add_auto_region :: proc(count := 1) {
  count := count
  REGION_ORDER :: []MapRegion {
    .Lake,
    .South,
    .Pond,
    .East,
  }
  for region in REGION_ORDER {
    if region not_in regions_gotten {
      add_classified_region(region)
      count -= 1
    }
    if count <= 0 {
      return
    }
  }
}

add_classified_auto_clicker :: proc(type : AutoType) {
  classifieds[classified_add_idx] = get_clicker_ad(type)
  classified_add_idx += 1
}

add_random_auto_clicker :: proc() {
  types := []AutoType {
    .Plant,
    .Harvest,
    .Till,
    .Water,
  }
  classifieds[classified_add_idx] = get_clicker_ad(rand.choice(types))
  classified_add_idx += 1
}

add_classified_upgrade :: proc(type : UpgradeType) {
  classifieds[classified_add_idx] = get_upgrade_ad(type)
  classified_add_idx += 1
}

add_random_upgrade :: proc($HIGH_LEVEL : bool) {
  when HIGH_LEVEL {
    types := []UpgradeType {
      .Water_Capacity,
      .Water_Effect,
      .Pumpkin_Yield,
      .Pumpkin_Yield,
      .Pumpkin_Yield,
      .Pumpkin_Speed,
      .Pumpkin_Speed,
      .Pumpkin_Speed,
    }
  } else {
    types := []UpgradeType {
      .Water_Capacity,
      .Water_Capacity,
      .Water_Capacity,
      .Water_Effect,
      .Water_Effect,
      .Water_Effect,
      .Pumpkin_Yield,
    }
  }
  classifieds[classified_add_idx] = get_upgrade_ad(rand.choice(types))
  classified_add_idx += 1
}



headline_text : [Headline]struct{ title : cstring, body : cstring, callback : #type proc() } = {
  .Intro = {
    "Pumpkin Mania: See the Shocking Statistics\n                   Behind the Rise in Popularity!",
    "The orange fruit is becoming more popular than ever before. From pumpkin spice lattes",
    proc() {
      clear_classifieds()
      add_classified_region(.Start)
      when DEBUG {
        add_classified_region(.Portal)
      }
    },
  },

  .New_Farm = {
    "The Ghostly Legend of the Pumpkin Patch:\n                        Is it True or Just a Myth?",
    "There's a new pumpkin patch coming to town, and with it comes a legend of ghostly app-",
    proc() {
      story_progress = .Halloween
      clear_classifieds()
      add_auto_region(2)
      add_random_upgrade(false)
      add_random_upgrade(false)
    },
  },

  .Good_Weather = {
    "Unseasonably Warm Weather Brings\n                         Record-Breaking Harvest",
    "Thanks to unseasonably warm weather, the pumpkin patch is experiencing a record-br-",
    proc() {
      clear_classifieds()
      add_auto_region(1)
      add_random_upgrade(false)
      add_random_upgrade(false)
    },
  },
  .Trick_Or_Treat = {
    "Halloween Festivities Take a\n             Spooky Turn at The Pumpkin Patch",
    "Trick-or-treating isn't the only Halloween tradition to be found at our historic pumpkin",
    proc() {
      clear_classifieds()
      add_random_upgrade(false)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(false)
      add_auto_region(1)
      add_random_auto_clicker()
    },
  },
  .Farmers_Market = {
    "Local Farmer's Market Held at\n                   Pumpkin Patch Draws in Crowds",
    "The pumpkin patch is the place to be on Saturday mornings, as a local farmer's market",
    proc() {
      clear_classifieds()
      add_random_upgrade(false)
      add_auto_region(1)
      add_random_upgrade(false)
      add_random_upgrade(false)
      add_random_upgrade(false)
      add_random_upgrade(false)
      add_random_upgrade(false)
    },
  },
  .Haunted_Happenings = {
    "Haunted Happenings Abound at\n                    Annual Pumpkin Patch Festival",
    "Get ready for a weekend of thrills and chills at the annual pumpkin patch festival. With",
    proc() {
      clear_classifieds()
      add_auto_region(1)
      add_random_upgrade(false)
      add_random_upgrade(false)
    },
  },
  .Work_Day = {
    "Pumpkin Patch Halloween Work Day:\n           Volunteers Needed to Help Prepare",
    "With Halloween just around the corner, the pumpkin patch is in need of a volunteer fo-",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_auto_region(1)
      add_random_upgrade(false)
      add_random_auto_clicker()
      add_random_upgrade(false)
      add_random_upgrade(false)
    },
  },


  .Ghost_Spotted = {
    "Ghost Spotted in Town: Is it the Haunted\n   Pumpkin Patch or Something More Sinister?",
    "Residents are on high alert after a ghost was spotted in the town center. Some believe",
    proc() {
      story_progress = .Haunted
      clear_classifieds()
      add_random_auto_clicker()
      add_random_upgrade(false)
      add_random_auto_clicker()
      add_random_upgrade(false)
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
    },
  },

  .Largest_Pumpkin = {
    "New Record Set for Largest Pumpkin\n                        at Haunted Pumpkin Patch",
    "A new record has been set for the largest pumpkin at the haunted pumpkin patch, with",
    proc() {
      clear_classifieds()
      add_random_upgrade(true)
      add_random_upgrade(false)
      add_random_auto_clicker()
      add_random_upgrade(false)
      add_random_auto_clicker()
    },
  },
  .Fundraiser = {
    "Haunted Pumpkin Patch Hosts Successful\n             Fundraiser for Local Animal Shelter",
    "The haunted pumpkin patch was the site of a successful fundraiser for the local animal",
    proc() {
      clear_classifieds()
      add_random_upgrade(false)
      add_random_auto_clicker()
    },
  },
  .Popular_1 = {
    "Haunted Pumpkin Patch Attracts\n                       Visitors From Near and Far",
    "People are coming from far and wide to experience the thrills and chills of the haunted",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
    },
  },
  .Unique_Experiance = {
    "Haunted Pumpkin Patch Offers\n       Unique Experience for Halloween Lovers",
    "For those who can't get enough of Halloween, the haunted pumpkin patch offers the p-",
    proc() {
      clear_classifieds()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(false)
    },
  },
  .Popular_2 = {
    "Haunted Pumpkin Patch Named Best\n       Halloween Destination by Local Magazine",
    "The haunted pumpkin patch has been named the best Halloween destination in the region",
    proc() {
      clear_classifieds()
      add_random_upgrade(false)
      add_random_upgrade(false)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_upgrade(true)
    },
  },


  .Missing_Persons = {
    "Several Missing Persons Reported:\n       Is the Haunted Pumpkin Patch Involved?",
    "Concern is growing as several missing persons reports have been filed in recent weeks.",
    proc() {
      story_progress = .Bad_Stuff
      clear_classifieds()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
    },
  },

  .Bad_1 = {
    "Ghostly Apparitions Haunt Town:\n       Is the Haunted Pumpkin Patch to Blame?",
    "Residents are on edge as ghostly apparitions begin to haunt the streets. Some believe",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
    },
  },
  .Bad_2 = {
    "Panic as Ghost Sightings Increase:  Is it the\n  Haunted Pumpkin Patch or Something More?",
    "As ghost sightings continue to increase, panic begins to grip the town. While some point",
    proc() {
      clear_classifieds()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
    },
  },
  .Bad_3 = {
    "Mystery Deepens as More\n                   Ghostly Encounters Reported",
    "The mystery of the ghostly encounters continues to deepen, as more and more people",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_upgrade(true)
    },
  },
  .Bad_4 = {
    "Expert Paranormal Investigators Called in\n         to Investigate Haunted Pumpkin Patch",
    "In the wake of the ghostly occurrences, expert paranormal investigators have been c-",
    proc() {
      clear_classifieds()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
    },
  },
  .Bad_5 = {
    "Town Meeting Called to Address Ghostly\n       Occurrences at Haunted Pumpkin Patch",
    "As concern about the ghostly occurrences at the haunted pumpkin patch grows, a town",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
    },
  },


  .Portal = {
    "Mysterious Portal Opens Up Near Haunted\nPumpkin Patch: Gateway to Another Dimension?",
    "Residents are in a state of shock after a mysterious portal opened up near the haun-",
    proc() {
      clear_classifieds()
      story_progress = .Post_Portal
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_classified_region(.Portal)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_auto_clicker()
    },
  },

  .Portal_1 = {
    "Ghostly Activity at Haunted Pumpkin Patch\n                 Shows No Signs of Slowing Down",
    "Despite efforts to contain the ghostly activity at the haunted pumpkin patch, the spir-",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_classified_region(.Portal)
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_upgrade(true)
    },
  },
  .Portal_2 = {
    "Residents Divided on Future of Haunted\n   Pumpkin Patch: \"It's a Part of Our History\"",
    "As the debate over the future of the haunted pumpkin patch continues, residents are",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_classified_region(.Portal)
      add_random_upgrade(true)
    },
  },
  .Portal_3 = {
    "Haunted Pumpkin Patch Closes Indefinitely\n                   as Ghostly Activity Escalates",
    "In the face of mounting ghostly activity, the haunted pumpkin patch has been forced to",
    proc() {
      clear_classifieds()
      add_random_auto_clicker()
      add_random_auto_clicker()
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_upgrade(true)
      add_random_auto_clicker()
      add_classified_region(.Portal)
      add_random_auto_clicker()
    },
  },
}

region_price := [MapRegion]int {
  .None = 0,
  .Start = 0,
  .Lake = 20,
  .Pond = 10,
  .South = 30,
  .East = 30,
  .Portal = 1000,
}

region_title := [MapRegion]cstring {
  .None = "",
  .Start = "Free Pumpkin Patch",
  .Lake = "Pumpkin Lake",
  .Pond = "Pumpkin Pond",
  .South = "Southern Fields",
  .East = "Eastern Farmland",
  .Portal = "Mysterious Portal",
}

region_text := [MapRegion]cstring {
  .None = "",
  .Start = "After 40 years I am selling my farm.\n"+
           "It's not haunted or anything, so don't\n"+
           "worry about that. I'm giving it away free\n"+
           "to anyone willing to take it!",
  .Lake = "Pumpkins love water, and I'm selling a\n"+
          "lake near the new pumpkin patch. If\n"+
          "the farmer is reading this, maybe buy\n"+
          "my lake?",
  .Pond = "You can never have enough pumpkin water\n"+
          "right? I'm selling a small pound near the\n"+
          "pumpkin patch. Hopefully this sells as well\n"+
          "as my brothers lake did.",
  .South = "I sold my farm a while ago, but I held on to\n"+
           "a bit of farmland in the south. I'm ready\n"+
           "to part with it, and once again I'd like to\n"+
           "say: it is not haunted!",
  .East = "I have a bit of farmland neighboring the\n"+
          "possitively spooky pumpkin patch. It would\n"+
          "be great for growing pumpkins, crops, or\n"+
          "even building a haunted attraction.",
  .Portal = "So... my farm was haunted. There is a\n"+
            "spooky portal past the lake. I'll sell\n"+
            "it to any interested buyers, but it's\n"+
            "going to cost you.",
}

get_region_ad :: proc(region : MapRegion) -> ClassifiedAd {
  @static base_cost := 0
  return ClassifiedAd {
    true,
    region_title[region],
    region_text[region],
    base_cost + region_price[region],
    int(region),
    proc(user_data : int) {
      base_cost += 10
      map_add_region(MapRegion(user_data))
    },
  }
}

get_clicker_ad :: proc(type : AutoType) -> ClassifiedAd {
  @static cost := 5
  rand_pos :: proc() -> V3 {
    cells, _ := slice.map_keys(all_tiles, context.temp_allocator)
    return cell_to_V3(rand.choice(cells))
  }
  rand_dir :: proc() -> V3 {
    x := (1.5 * rand.float32()) + 0.25
    y := 2 - x
    if rand.float64() > 0.5 {
      x = -x
    }
    if rand.float64() > 0.5 {
      y = -y
    }
    return V3{ x, 0, y }
  }
  switch type {
    case .Plant:
      return ClassifiedAd {
        true,
        "Helpful Planter",
         /////////////////////////////////////////
        "Farming is hard, for just a small\n"+
        "investment you can automate a bit of your\n"+
        "work. Helpful Planters will wander your\n"+
        "farm and plant pumpkins.",
        cost,
        0,
        proc(user_data : int) {
          cost += 5
          append(&inventory.auto_clicker, AutoClicker{
            type = .Plant,
            pos = rand_pos(),
            dir = rand_dir(),
            cooldown = 0.0,
          })
        },
      }
    case .Till:
      return ClassifiedAd {
        true,
        "Wandering Tiller",
         /////////////////////////////////////////
        "Wanders and tills soil. You can rest\n"+
        "assured that there is nothing super-\n"+
        "natural about it!",
        cost,
        0,
        proc(user_data : int) {
          cost += 5
          append(&inventory.auto_clicker, AutoClicker{
            type = .Till,
            pos = rand_pos(),
            dir = rand_dir(),
            cooldown = 0.0,
          })
        },
      }
    case .Water:
      return ClassifiedAd {
        true,
        "Irrigation System",
         /////////////////////////////////////////
        "A way to fully automate watering\n"+
        "your crops. It used pipes to move\n"+
        "water, not departed spirits.",
        cost,
        0,
        proc(user_data : int) {
          cost += 5
          append(&inventory.auto_clicker, AutoClicker{
            type = .Water,
            pos = rand_pos(),
            dir = rand_dir(),
            cooldown = 0.0,
          })
        },
      }
    case .Harvest:
      return ClassifiedAd {
        true,
        "Pumpkin Reaper",
         /////////////////////////////////////////
        "Drawing on years of experiance with\n"+
        "reaping, our patented Pumpkin Reapers\n"+
        "will automaticaly harvest your field\n"+
        "in no time.",
        cost,
        0,
        proc(user_data : int) {
          cost += 5
          append(&inventory.auto_clicker, AutoClicker{
            type = .Harvest,
            pos = rand_pos(),
            dir = rand_dir(),
            cooldown = 0.0,
          })
        },
      }
  }

  return {}
}

UpgradeType :: enum { Water_Capacity, Water_Effect, Pumpkin_Yield, Pumpkin_Speed }

upgrade_costs := [UpgradeType]int {
  .Water_Capacity = 5,
  .Water_Effect = 5,
  .Pumpkin_Yield = 5,
  .Pumpkin_Speed = 5,
}

upgrade_title := [UpgradeType]cstring {
  .Water_Capacity = "Water Bucket",
  .Water_Effect = "Mineral Tablets",
  .Pumpkin_Yield = "Fertilizer",
  .Pumpkin_Speed = "Secret Soil Recipe",
}

upgrade_text := [UpgradeType]cstring {
  .Water_Capacity = "With an extra water bucket you\n"+
                    "will be able to carry more water.",
  .Water_Effect = "There mineral tablets will add an\n"+
                  "extra kick to your water. Great for\n"+
                  "farmers that want a faster yeild.",
  .Pumpkin_Yield = "This fertilizer will increase your\n"+
                   "pumpkin yield, more pumpkin is\n"+
                   "always better.",
  .Pumpkin_Speed = "My pattented (and not at all sinister)\n"+
                   "soil recipe will grow your pumpkins in\n"+
                   "less time than before.",
}

get_upgrade_ad :: proc(type : UpgradeType) -> ClassifiedAd {
  /*
  water_capacity : int,
  water_effect : f32,
  pumpkin_yeild : int,
  pumpkin_speed : f32,
  */
  @static base_cost := 0
  return ClassifiedAd {
    true,
    upgrade_title[type],
    upgrade_text[type],
    base_cost + upgrade_costs[type],
    int(type),
    proc(user_data : int) {
      type := UpgradeType(user_data)
      base_cost += 3
      upgrade_costs[type] = int(1.25 * f32(upgrade_costs[type]))
      switch type {
        case .Water_Capacity:
          inventory.water_capacity += 5
        case .Water_Effect:
          inventory.water_effect = (0.66 * inventory.water_effect) + 0.33
        case .Pumpkin_Yield:
          inventory.pumpkin_yeild += 1
        case .Pumpkin_Speed:
          inventory.pumpkin_speed = (0.75 * inventory.pumpkin_speed) + 0.25
          if story_progress == .Haunted {
            story_progress = .Missing_Persons
          }
      }
    },
  }
}
