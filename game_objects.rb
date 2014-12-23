# Copyright 2014 Aaron M. Taylor

# Card class for blackjack game
class Card
  SUITS = [:spade, :heart, :diamond, :club]
  SUIT_NAMES = { spade: 'Spades', heart: 'Hearts', diamond: 'Diamonds', club: 'Clubs' }
  NUM_NAMES = { 2 => 'Two', 3 => 'Three', 4 => 'Four', 5 => 'Five', 6 => 'Six',
                7 => 'Seven', 8 => 'Eight', 9 => 'Nine', 10 => 'Ten',
                11 => 'Jack', 12 => 'Queen', 13 => 'King', 14 => 'Ace' }

  def initialize(suit, num)
    @suit = suit
    @num = num
  end

  def value
    return @num if @num <= 10 # number cards have their own value
    return 1 if @num == 14 # ace defaults to 1 for now
    10 # value for face cards
  end

  def to_s
    "[#{NUM_NAMES[@num]} of #{SUIT_NAMES[@suit]}]"
  end
end

# A wrapper class for a deck of 52 cards, provides appropriate methods for gameplay
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
    if @cards.count != 52
      # @cards.each { |c| puts "card: #{c}" }
      fail "on shuffle, #{@cards.count} cards found in the deck"
    end
    # iterates through the deck once
    (0...@cards.count).each do |cur_index|
      # choose a random index after the current
      random_index = Random.rand(@cards.count - cur_index) + cur_index
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
    reset_cards
  end

  def reset_cards
    @hand = []
    @stay = false
  end

  def take(card)
    @hand.push card
  end

  def count
    @hand.reduce(0) { |a, e| a + e.value }
  end

  def stay
    @stay = true
  end

  def bust?
    count > 21
  end

  def hand_to_s
    @hand.reduce('') { |a, e| a + "#{e}, " }
  end
end
