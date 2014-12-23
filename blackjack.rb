# Copyright 2014 Aaron M. Taylor

require './game_objects.rb'
require './strings.rb'

# utility method that retrieves a number from command line input
# repeatedly asks if the given input is invalid for conversion
def prompt_for_num(prompt)
  puts prompt
  loop do
    begin
      return Integer(STDIN.gets.chomp) # throws an error for invalid numbers
    rescue ArgumentError
      puts 'Please enter a valid number'
    end
  end
end

# A command line blackjack game
class Blackjack
  attr_accessor :deck

  def initialize(num_players = 4)
    @dealer = Player.new(true)
    @players = []
    num_players.times do |_i|
      @players << Player.new
    end
    @deck = Deck.new
  end

  def play_hand
    @players.each_index do |index|
      p = @players[index]
      puts p
    end
  end

  # reads command line input to handle gameplay
  def play
    loop do
      response = STDIN.gets.chomp
      break if response == 'exit'
      puts HELP_STR if response == 'help'
      puts(response)
    end
  end
end

# Scripting code to setup the game and initialize play
puts BLACKJACK_TITLE

# retrieves the count
num_players = prompt_for_num(PLAYER_COUNT_PROMPT)

game = Blackjack.new(num_players)

puts START_STR
puts('Created game, each player has $1000')

game.play
