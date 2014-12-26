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

  def ace?
    num == 14 || num == 1
  end

  def lower_ace
    return false unless @num == 14
    @num = 1
    true
  end

  def raise_ace
    return false unless @num == 1
    @num = 14
    true
  end

  def to_s
    "[#{NUM_NAMES[@num]} of #{SUIT_NAMES[@suit]}]"
  end

  def ==(other)
    return true if other.suit == @suit && other.num == @num
    false
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
# Hand class for blackjack game
#
# keeps track of a single hand and its status
#
class Hand
  def initialize
    @cards = []
    @bet = []
  end

  def push(card)
    @cards.push(card)
  end

  def split
    return unless can_split
    c = @cards.pop
    h = Hand.new
    h.push(c)
    h
  end

  def count
    @cards.reduce(0) { |a, e| a + e.value }
  end

  # TODO: add functionality for splitting multiple times
  def can_split
    @cards.count == 2 && @cards[0] == @cards[1]
  end

  def first_ace_high
    @cards.each_with_index { |card, i| return i if card.num == 14 }
    nil
  end

  def reset
  end

  def to_s
    str = @cards.reduce('') { |a, e| a + "#{e}, " }
    str.slice(0, str.length - 2)
  end
end

##############################################
# Player class for blackjack game
#
# keeps track of hands and in-game state
#
class Player
  attr_accessor :standing
  attr_accessor :cash
  attr_accessor :bet_amt
  attr_accessor :hands

  def initialize(dealing = false)
    @dealing = dealing
    @cash = 1000
    end_round(0)
    reset
  end

  # called as soon as a player's winnings are known (bust or after dealer has gone)
  def end_round(winnings)
    @cash += winnings
    @bet_amt = 0
    @standing = true
  end

  # called to reset the palyer for the next round of play
  def reset
    @standing = false
    @hands = []
    @hands.push Hand.new
  end

  # keeps track of a players bets, returning false is cash in insufficient
  def bet(amount)
    return false if amount > @cash
    @cash -= amount
    @bet_amt += amount
    true
  end

  def take(card, hand_index = 0)
    @hands[hand_index].push(card)
    adjust_aces
  end

  # counts the value of the player's hand, converting aces to low if necessary
  # has side effects that effect the aces in hand if necessary
  def adjust_aces(hand_index = 0)
    # if the count is bust but there is an ace, lower the ace
    h = @hands[hand_index]
    index = h.first_ace_high
    h[index].lower_ace if h.count > 21 && index
    h.count
  end

  # takes the second of the two identical cards from the specified hand and moves it to a new hand
  def split(hand_index)
    new_hand = @hands[hand_index].split
    @hands.push(new_hand)
  end

  def bust?
    @hands.each { |h| return true if h.count > 21 }
    false
  end

  def blackjack?(hand_index = 0)
    @hands[hand_index].count == 2 && count == 21
  end
end

##############################################
# Player class for blackjack game
#
# subclass of player that handles standard gameplay logic for the dealer
#
class Dealer < Player
  def will_hit
    count < 17
  end

  def hand_to_s
    @hands[0].to_s
  end
end
