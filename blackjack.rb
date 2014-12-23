# Copyright 2014 Aaron M. Taylor

require './card.rb'
require './player.rb'
require './strings.rb'

# A command line blackjack game
class Blackjack
  attr_accessor :deck

  def initialize(num_players = 4)
    @dealer = Player.new(true)
    @players = []
    num_players.times do |_i|
      @players << Player.new
    end
    @deck = Card.full_deck
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
puts 'Please enter the number of players'
num_players = 0
loop do
  begin
    num_players = Integer(STDIN.gets.chomp) # throws an error for invalid numbers
    break
  rescue ArgumentError
    puts 'Please enter a valid number'
  end
end

game = Blackjack.new(num_players)

puts('Created game, each player has $1000')

game.play
