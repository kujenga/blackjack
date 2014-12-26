#!/usr/bin/env ruby
# Copyright 2014 Aaron M. Taylor

require './blackjack.rb'

###########################################################
# Scripting code to setup the game and initialize play
###########################################################

puts BLACKJACK_TITLE

# retrieves the count
num_players = prompt_for_num(PLAYER_COUNT_PROMPT)

# creates a new blackjack game with the user-specificed number of players
game = Blackjack.new(num_players)

# begins gameplay with an interpreter loop inside the Blackjack class
game.play
