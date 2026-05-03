# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

game = Game.find_or_initialize_by(name: "Skribbl")
game.update!(config: {
    word_list: [
      # Animals
      "elephant", "penguin", "giraffe", "butterfly", "octopus", "kangaroo", "chameleon", "dolphin",
      "peacock", "lobster", "flamingo", "jellyfish", "porcupine", "hamster", "parrot", "tortoise",
      "goldfish", "crocodile", "spider web", "shark",

      # Food & Drinks
      "pizza", "sushi", "pancakes", "ice cream", "french fries", "birthday cake", "hot dog",
      "milkshake", "fried egg", "popcorn", "watermelon", "chocolate", "sandwich", "burrito", "donut",
      "noodles", "tacos", "smoothie", "peanut butter", "lemonade",

      # Sports & Games
      "basketball", "skateboard", "bowling", "surfing", "tennis racket", "yoga", "trampoline",
      "arm wrestling", "figure skating", "rock climbing", "chess", "volleyball", "archery",
      "table tennis", "swimming pool", "tug of war", "marathon", "boxing ring",

      # Music & Art
      "guitar", "drums", "microphone", "ballet dancer", "headphones", "piano", "violin",
      "paintbrush", "graffiti", "photograph", "orchestra", "disco ball", "karaoke",
      "music festival", "saxophone",

      # Nature & Weather
      "volcano", "waterfall", "rainbow", "tornado", "lightning", "avalanche", "sunset",
      "quicksand", "coral reef", "northern lights", "earthquake", "desert island", "glacier",
      "campfire", "stargazing", "full moon", "ocean wave",

      # Around the House
      "umbrella", "alarm clock", "refrigerator", "bathtub", "chandelier", "bookshelf",
      "washing machine", "rocking chair", "pillow fight", "bunk bed", "vacuum cleaner",
      "remote control", "doorbell", "fireplace", "lava lamp", "bean bag",

      # Transportation
      "bicycle", "helicopter", "hot air balloon", "roller coaster", "submarine", "spaceship",
      "monster truck", "sailboat", "ambulance", "school bus", "motorcycle", "cruise ship",
      "fire truck", "tractor", "cable car", "go kart",

      # Everyday Life
      "selfie", "high five", "road trip", "traffic jam", "grocery shopping", "first date",
      "job interview", "morning coffee", "bubble bath", "sunburn", "lost keys",
      "video call", "alarm snooze", "car wash", "waiting room",

      # Professions & People
      "firefighter", "astronaut", "lifeguard", "magician", "detective", "ninja", "pirate",
      "scarecrow", "clown", "superhero", "dentist", "chef", "cowboy", "pilot",
      "zookeeper", "bodyguard",

      # Emotions & Actions
      "laughing", "sleepwalking", "daydreaming", "heartbreak", "stage fright", "brain freeze",
      "goosebumps", "happy tears", "facepalm", "yawning", "blushing",

      # Pop Culture & Fun
      "time machine", "treasure map", "haunted house", "magic carpet", "escape room",
      "photobomb", "plot twist", "binge watching", "spoiler alert", "costume party",
      "comic book", "action figure", "board game",

      # Brands & Games
      "minecraft", "lego", "monopoly", "spotify", "netflix", "google", "mario kart",
      "tetris", "pac man", "angry birds", "pokemon", "fortnite", "instagram",
      "youtube", "uber", "tesla", "nike", "playstation", "xbox", "tinder",

      # Technology
      "wifi signal", "selfie stick", "robot", "virtual reality", "emoji", "password",
      "loading screen", "autocorrect", "screenshot", "bluetooth", "drone", "smartwatch",
      "charging cable", "pop up ad",

      # Space & Science
      "black hole", "solar system", "alien", "shooting star", "astronaut helmet",
      "telescope", "lab coat", "magnet", "microscope", "dna",

      # Random & Tricky
      "shadow puppet", "paper airplane", "belly flop", "tongue twister",
      "cloud nine", "couch potato", "air guitar", "cannonball",
      "piggyback ride", "thumbs up", "fist bump", "wrecking ball", "speed bump",
      "bubble wrap", "duct tape", "fortune cookie", "lava floor", "plot armor",
      "rickroll", "vending machine", "windmill", "zip line"
    ],
    tagline: "Draw. Guess. Dominate.",
    rounds: 8,
    draw_duration: 80,
    word_selection_duration: 10,
    number_of_words: 3
  })