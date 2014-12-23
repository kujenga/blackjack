# Copyright 2014 Aaron M. Taylor

require './card.rb'

# A command line blackjack game
class Blackjack
  attr_accessor :deck

  def initialize
    @deck = Card.full_deck
  end

  # reads command line input to handle gameplay
  def play
    loop do
      response = STDIN.gets.chomp
      break if response == 'exit'
      puts(response)
    end
  end
end

game = Blackjack.new

puts('Created game')

game.play
