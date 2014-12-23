# Copyright 2014 Aaron M. Taylor

# Card class for blackjack game
class Card
  SUITS = [:spade, :heart, :diamond, :club]

  def initialize(suit, num)
    @suit = suit
    @num = num
  end

  def to_s
    "[#{num} of #{@suit}]"
  end
end

# holds a deck of 52 cards, provides appropriate methods for gameplay
class Deck
  def initialize
    build_deck
    shuffle
  end

  def build_deck
    @cards = []
    Card::SUITS.each do |suit|
      (2..14).each do |i|
        @cards << Card.new(suit, i)
      end
    end
    shuffle
  end

  def draw
    return nil unless @cards.any?
    @cards.pop
  end

  # implements the Fischer-Yates or Knuth shuffling algorithm
  def shuffle
    fail "on shuffle, #{@cards.count} cards found in the deck" if @cards.count != 52
    # iterates through the deck once
    (0..@cards.count).each do |cur_index|
      # choose a random index after the current
      random_index = Random.rand(@cards.count - 1) + cur_index
      # swap the current with the card at the random index
      @cards[cur_index], @cards[random_index] = @cards[random_index], @cards[cur_index]
    end
  end
end

# Player class for blackjack game
class Player
  attr_accessor :cash

  def initialize(dealing = false)
    @dealing = dealing
    @cash = 1000
    @hand = []
  end

  def hit(card)
    @hand.push card
  end

  def count
  end
end
