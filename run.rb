#!/usr/bin/env ruby
# Copyright 2014 Aaron M. Taylor

require './blackjack.rb'

###########################################################
# Scripting code to setup the game and initialize play
###########################################################

puts `ruby test_game_objects.rb` if ARGV.count > 0 && ARGV[0].match(/test/)

puts BLACKJACK_TITLE

# creates a new blackjack game with the user-specificed number of players
game = Blackjack.new

# begins gameplay with an interpreter loop inside the Blackjack class
game.play
