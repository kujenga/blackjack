# Copyright 2014 Aaron M. Taylor

# Player class for blackjack game
class Player
  attr_accessor :cash

  def initialize(dealing = false)
    @dealing = dealing
    @cash = 1000
  end
end
