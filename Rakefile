# Rakefile for testing and execution
# Copyright 2014 Aaron M. Taylor

task default: %w[test]

task :run do
  require './blackjack.rb'
  puts BLACKJACK_TITLE

  # creates a new blackjack game with the user-specificed number of players
  game = Blackjack.new

  # begins gameplay with an interpreter loop inside the Blackjack class
  game.play
end

task :test do
  ruby "test_game_objects.rb"
end

