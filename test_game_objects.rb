require 'minitest/unit'
require 'minitest/autorun'
require './game_objects.rb'

class TestCard < MiniTest::Unit::TestCase
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

class TestDeck < MiniTest::Unit::TestCase
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

class TestHand < MiniTest::Unit::TestCase
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

class TestPlayer < MiniTest::Unit::TestCase
  def setup
    @player = Player.new
  end
end

class TestDealer < MiniTest::Unit::TestCase
  def setup
    @dealer = Dealer.new
  end
end
