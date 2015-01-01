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

  # converts an ace high to an ace low
  def lower_ace
    return false unless @num == 14
    @num = 1
    true
  end

  # converts an ace low to an ace high
  def raise_ace
    return false unless @num == 1
    @num = 14
    true
  end

  def to_s
    "[#{NUM_NAMES[@num]} of #{SUIT_NAMES[@suit]}]"
  end

  def ==(other)
    other.suit == @suit && other.num == @num
  end
end

####################################################
# A wrapper for a deck of 52 cards
#
# provides methods to build the deck, shuffle it, and draw cards
#
class Deck
  attr_accessor :num_decks

  def initialize(num_decks = 1)
    @num_decks = num_decks
    build_deck
  end

  def build_deck
    @cards = []
    @num_decks.times do
      Card::SUITS.each do |suit|
        (2..14).each do |i|
          @cards << Card.new(suit, i)
        end
      end
    end
    shuffle
  end

  def count
    @cards.count
  end

  def draw
    return nil unless @cards.any?
    @cards.pop
  end

  # implements the Fischer-Yates or Knuth shuffling algorithm
  # for an efficient and fully randomized shuffle
  def shuffle
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
  attr_accessor :bet
  attr_accessor :standing
  attr_accessor :surrendered

  def initialize
    @cards = []
    @bet = 0
    @standing = false
    @surrendered = false
  end

  def push(card)
    @cards.push(card)
  end

  # two cards are present and they have equal value
  # true equality is not necessary, as pairs of face cards can be split
  def splittable
    @cards.count == 2 && @cards[0].value == @cards[1].value
  end

  # splits the hand and returns a new hand with the other half
  def split
    return unless splittable
    c = @cards.pop
    h = Hand.new
    h.push(c)
    h.bet = @bet
    h
  end

  # counts the total value of the hand
  def count
    @cards.reduce(0) { |a, e| a + e.value }
  end

  def bust?
    count > 21
  end

  def out?
    bust? || @surrendered || @standing
  end

  def blackjack?
    @cards.count == 2 && count == 21
  end

  # returns the index of the first ace high in case it needs to be lowered
  def first_ace_high
    @cards.each_with_index { |card, i| return i if card.num == 14 }
    nil
  end

  # allows for cleaner access of cards
  def [](index)
    @cards[index]
  end

  def status
    return 'bust' if bust?
    return 'standing' if @standing
    return 'surrendered' if @surrendered
    'active'
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
  attr_accessor :cash
  attr_accessor :hands

  def initialize(dealing = false)
    @dealing = dealing
    @cash = 1000
    reset
  end

  # called to reset the palyer for the next round of play
  def reset
    @hands = []
    @hands.push Hand.new
  end

  # called as soon as a player's winnings are known (bust or after dealer has gone)
  def return_winnings(winnings)
    @cash += winnings
  end

  # keeps track of a players bets, returning false is cash in insufficient
  def bet(amount, h_index)
    return false if (amount * @hands.count) > @cash
    @cash -= amount
    @hands[h_index].bet += amount
    true
  end

  def take(card, h_index)
    @hands[h_index].push(card)
    adjust_aces(h_index)
  end

  # counts the value of the player's hand, converting aces to low if necessary
  # has side effects that effect the aces in hand if necessary
  def adjust_aces(h_index)
    # if the count is bust but there is an ace, lower the ace
    h = @hands[h_index]
    index = h.first_ace_high
    h[index].lower_ace if h.count > 21 && index
    h.count
  end

  def can_split(h_index)
    @hands[h_index].splittable && @cash >= @hands[h_index].bet
  end

  def has_split?
    return @hands.count < 1
  end

  # takes the second of the two identical cards from the specified hand and moves it to a new hand
  def split(h_index)
    new_hand = @hands[h_index].split
    @cash -= new_hand.bet
    @hands.push(new_hand)
  end

  def finished?
    @hands.each { |h| return false unless h.out? }
    true
  end

  # allows for cleaner access of player's hands
  def [](index)
    @hands[index]
  end
end

##############################################
# Player class for blackjack game
#
# subclass of player that handles standard gameplay logic for the dealer
# provides simpler methods since the dealer never doubles, splits, or surrenders
#
class Dealer < Player
  # because the dealer never splits
  def hand
    @hands.first
  end

  def will_hit
    hand.count < 17
  end

  def hand_to_s
    hand.to_s
  end

  def bust?
    hand.bust?
  end

  def count
    hand.count
  end

  def top_card
    hand[0]
  end

  def to_s
    "Count: #{count} Hand: #{hand}"
  end
end
