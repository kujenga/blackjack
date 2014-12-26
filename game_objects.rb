# Copyright 2014 Aaron M. Taylor

# This file contains class definitions of in-game objects

#########################################
# Card class for blackjack
#
# holds a suit and number
# provides a value method specific for blackjack gameplay
#
class Card
  SUITS = [:spade, :heart, :diamond, :club].freeze
  SUIT_NAMES = { spade: 'Spades', heart: 'Hearts', diamond: 'Diamonds', club: 'Clubs' }.freeze
  NUM_NAMES = { 1 => 'Ace Low', 2 => 'Two', 3 => 'Three', 4 => 'Four', 5 => 'Five',
                6 => 'Six', 7 => 'Seven', 8 => 'Eight', 9 => 'Nine', 10 => 'Ten',
                11 => 'Jack', 12 => 'Queen', 13 => 'King', 14 => 'Ace High' }.freeze

  attr_accessor :suit
  attr_accessor :num

  def initialize(suit, num)
    @suit = suit
    @num = num
  end

  # returns an integer value representing the value of the card according to blackjack rules
  def value
    return @num if @num <= 10 # number cards have their own value
    return 11 if @num == 14 # ace high is worth 11
    10 # value for face cards
  end

  def ==(other)
    return true if other.suit == @suit && other.num == @num
    false
  end

  def to_s
    "[#{NUM_NAMES[@num]} of #{SUIT_NAMES[@suit]}]"
  end
end

####################################################
# A wrapper class for a deck of 52 cards
#
# provides methods to build the deck, shuffle it, and draw cards
#
class Deck
  def initialize
    build_deck
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

##############################################
# Player class for blackjack game
#
# keeps track of a hand, providing methods to count score
# keeps track of in-game state
#
class Player
  attr_accessor :standing
  attr_accessor :cash
  attr_accessor :bet_amt

  def initialize(dealing = false)
    @dealing = dealing
    @cash = 1000
    end_round(0)
    reset
  end

  def end_round(winnings)
    @cash += winnings
    @bet_amt = 0
    @standing = true
  end

  def reset
    @standing = false
    @hand = []
  end

  def bet(amount)
    return false if amount > @cash
    @cash -= amount
    @bet_amt += amount
    true
  end

  def take(card)
    @hand.push card
  end

  def count
    @hand.reduce(0) { |a, e| a + e.value }
  end

  # TODO: add functionality for splitting multiple times
  def can_split
    @hand.count == 2 && @hand[0] == @hand[1]
  end

  def bust?
    count > 21
  end

  def blackjack?
    @hand.count == 2 && count == 21
  end

  def hand_to_s
    hand = @hand.reduce('') { |a, e| a + "#{e}, " }
    hand.slice(0, hand.length - 2)
  end
end

# subclass of player that handles the standard gameplay logic for the dealer
class Dealer < Player
  def will_hit
    count < 17
  end
end
