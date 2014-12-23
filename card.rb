# Copyright 2014 Aaron M. Taylor

# Card class for blackjack game
class Card
  def initialize(suit, num)
    @suit = suit
    @num = num
  end

  def to_s
    "[#{num} of #{@suit}]"
  end

  def self.full_deck
    deck = []
    [:spade, :heart, :diamond, :club].each do |suit|
      (2..14).each do |i|
        deck << Card.new(suit, i)
      end
    end
    deck
  end
end
