# Unit tests for blackjack

require 'minitest/autorun'
require 'minitest/unit'
require './game_objects.rb'

class TestCard < MiniTest::Test
  def setup
    @card = Card.new(:spade, 4)
    @king = Card.new(:spade, 13)
    @ace = Card.new(:spade, 14)
  end

  def test_ace_handling
    assert_equal 11, @ace.value, 'Ace High should have a value of 11'
    assert @ace.ace?, 'Ace must be recognized as an ace'
    refute @ace.raise_ace, 'Cannot raise an Ace High'
    assert @ace.lower_ace, 'Ace High should be able to be lowered'
    assert_equal 1, @ace.value, 'Lowered Ace should have value of 1'
    assert @ace.raise_ace, 'Ace low should be able to be raised'
    assert_equal 11, @ace.value, 'Ace High should have a value of 11 after manipulation'
  end

  def test_values
    assert_equal 10, @king.value, 'Face cards should have value of 10'
    assert_equal @card.num, @card.value, 'Number cards should have value equal to their number'
  end

  def test_equality
    assert_equal Card.new(:heart, 9), Card.new(:heart, 9), 'Equal cards should be equal'
    refute_equal @card, @king, 'Different cards should be unequal'
  end
end

class TestDeck < MiniTest::Test
  def setup
    @deck = Deck.new
    @multideck = Deck.new(6)
  end

  def test_deck_count
    assert_equal 52, @deck.count, 'Normal deck should have 52 cards'
    assert_equal 52 * 6, @multideck.count, '6 Multideck should have 6*52 cards'
  end

  def test_shuffle_and_draw
    assert @deck.shuffle, 'Deck should shuffle without error'
    assert @multideck.shuffle, 'Multideck should shuffle without errors'
    10.times do
      refute_nil @deck.draw, 'Deck should draw a card'
      refute_nil @multideck.draw, 'Deck should draw a card'
    end
    assert @deck.shuffle, 'Deck with drawn cards should shuffle without error'
    assert @multideck.shuffle, 'Multideck with drawn cards should shuffle without errors'
  end
end

class TestHand < MiniTest::Test
  def setup
    @blackjack = Hand.new
    @blackjack.push(Card.new(:spade, 14))
    @blackjack.push(Card.new(:spade, 11))
  end

  def test_count
    @hand = Hand.new
    @hand.push(Card.new(:spade, 8))
    assert_equal 8, @hand.count
    @hand.push(Card.new(:spade, 13))
    assert_equal 18, @hand.count
  end

  def test_split
    @hand = Hand.new
    @hand.push(Card.new(:heart, 10))
    @hand.push(Card.new(:club, 13))
    assert @hand.splittable?, 'Hand with cards of equal value should be splittable'

    refute @blackjack.splittable?, 'Cannot split a blackjack hand'

    new_hand = @hand.split
    assert_equal 10, @hand.count, 'Count should be half after split for old hand'
    assert_equal 10, new_hand.count, 'Count should be half after split for new hand'
    assert_equal @hand.bet, new_hand.bet, 'Split hands should have the same bet'
  end

  def test_bust
    @hand = Hand.new
    @hand.push(Card.new(:spade, 8))
    @hand.push(Card.new(:spade, 13))
    refute @hand.bust?, 'Hand is not bust'
    @hand.push(Card.new(:diamond, 9))
    assert @hand.bust?, 'Hand should be recognied as bust'
  end

  def test_blackjack
    assert @blackjack.blackjack?, 'hand has blackjack and should be recognized as such'
  end

  def test_first_ace_high
    @hand = Hand.new
    @hand.push(Card.new(:spade, 8))
    assert_nil @hand.first_ace_high, 'Hand does not contain an ace'
    @hand.push(Card.new(:spade, 14))
    assert_equal 1, @hand.first_ace_high, 'Hand contains an ace at position 1'
  end
end

class TestPlayer < MiniTest::Test
  def setup
    @player = Player.new
    @player2 = Player.new
    @seven = Card.new(:spade, 7)
    @jack = Card.new(:heart, 11)
    @queen = Card.new(:diamond, 12)
    @ace = Card.new(:spade, 14)
  end

  def test_betting
    refute @player.bet(10000, 0), 'Cannot bet more than current cash level'
    amount = @player.cash
    assert @player.bet(100, 0), 'should be able to bet an amount less than cash level'
    assert_equal amount - 100, @player.cash, 'Player\'s cash value should decrease by the amount bet'
  end

  def test_ace_adjustment
    @player.take(@seven, 0, false)
    assert_equal @player[0].count, @player.adjust_aces(0), 'If no ace is present, nothing should be changed'
    @player.take(@ace, 0, false)
    assert_equal @player[0].count, @player.adjust_aces(0), 'If ace is present but not bust, nothing should be changed'
    @player.take(@seven, 0, false)    
    refute_equal @player[0].count, @player.adjust_aces(0), 'If ace is present and bust, should be adjusted'
    refute @player[0].bust?, 'Player hand should not bust after ace adjustment'
  end

  def test_splitting
    refute @player.can_split?(0), 'Player with non-paired cards cannot split'
    @player2.take(@jack, 0)
    @player2.take(@queen, 0)
    assert @player2.can_split?(0), 'Player should be able to split'
    @player2.split(0)
    assert @player2.has_split?, 'Player should have split after `split` call'
  end
end

class TestDealer < MiniTest::Test
  def setup
    @dealer = Dealer.new
  end

  def test_will_hit
    @dealer.take(Card.new(:spade, 13), 0)
    assert @dealer.will_hit, 'Dealer should hit with a count of 10'
    @dealer.take(Card.new(:spade, 4), 0)
    assert @dealer.will_hit, 'Dealer should hit with a count of 14'
    @dealer.take(Card.new(:spade, 7), 0)
    refute @dealer.will_hit, 'Dealer should not hit with a count of 21'
  end
end
