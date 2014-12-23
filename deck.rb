# Copyright 2014 Aaron M. Taylor

require './card.rb'

# holds a deck of 52 cards, provides appropriate methods for gameplay
class Deck
  def initialize
    @cards = []
    Card::SUITS.each do |suit|
      (2..14).each do |i|
        @cards << Card.new(suit, i)
      end
    end
    shuffle
  end

  # implements the Fischer-Yates or Knuth shuffling algorithm
  def shuffle
    # iterates through the deck once
    (0..@cards.count).each do |cur_index|
      # choose a random index after the current
      random_index = Random.rand(@cards.count - 1) + cur_index
      # swap the current with the card at the random index
      @cards[cur_index], @cards[random_index] = @cards[random_index], @cards[cur_index]
    end
  end
end
