# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Game.find_or_create_by(name: "Skribbl") do |game|
  game.config = {
    word_list: ["elephant", "guitar", "volcano", "bicycle", "umbrella"],
    tagline: "Draw. Guess. Dominate.",
    rounds: 8,
    draw_duration: 80,
    word_selection_duration: 10,
    number_of_words: 3
  }
end