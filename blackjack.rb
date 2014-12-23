# Copyright 2014 Aaron M. Taylor

require './card.rb'

# A command line blackjack game
class Blackjack
  attr_accessor :deck

  def initialize
    @deck = Card.full_deck
  end
end

game = Blackjack.new

puts("Created game with deck of size: #{game.deck.count}")
