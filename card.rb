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
