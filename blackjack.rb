# Copyright 2014 Aaron M. Taylor

require './game_objects.rb'
require './strings.rb'

###################
# utility methods that retrieve values from command line input
###################

# repeatedly prompts if the given input is invalid for conversion
def prompt_for_num(prompt)
  print(prompt + ' ')
  loop do
    begin
      return Integer(STDIN.gets.chomp) # throws an error for invalid numbers
    rescue ArgumentError
      puts 'Please enter a valid number'
    end
  end
end

# utility method for retrieving a y/n answer from command line input
def prompt_for_yn(prompt)
  print "#{prompt} [y/n] "
  loop do
    response = STDIN.gets.chomp
    return true if response.match(/y|Y/)
    return false if response.match(/n|N/)
    puts 'invalid response, please try again'
  end
end

# black-jack specific utility method for retrieving player action from command line input
def prompt_for_action(prompt)
  print(prompt + ' ')
  loop do
    response = STDIN.gets.chomp
    # hit, stand, double, surrender
    return response if response.match(/h|H|s|S|d|D|e|E/)
    print 'invalid response, please try again '
  end
end

##################################################
# A command line blackjack game
##################################################
#
# `play` method is the entry point for user interactions
#
class Blackjack
  attr_accessor :deck

  def initialize(num_players = 4)
    @dealer = Dealer.new(true)
    @players = []
    num_players.times do |_i|
      @players << Player.new
    end
    @deck = Deck.new
  end

  # deals a single card to the passed in player, then returns that card
  def deal_one(player)
    c = @deck.draw
    player.take(c)
    c
  end

  # deals each player two cards to begin the hand
  def initial_deal
    @players.each do |p|
      p.take(deal_one(p))
      # deal_one(p)
    end
    deal_one(@dealer)
    deal_one(@dealer)
  end

  # prompts each player for their initial bets for this hand
  def initial_bets
    puts 'INITIAL BETS:'
    @players.each_index do |index|
      p = @players[index]
      bet = prompt_for_num("Player #{index}: #{p.hand_to_s}, your count is #{p.count} and you have #{p.cash}. What is your initial bet?")
      puts "Player #{index} does not have enough funds, betting 0" unless p.bet(bet)
    end
    puts ''
  end

  # propmts the player for a split if one is possible
  def prompt_split(player, h_index)
    return unless prompt_for_yn("Would you like to split hand #{h_index}?")
    player.split(h_index)
    puts "hand #{h_index} is now: #{player.hand_to_s(h_index)} with count #{player.count(h_index)}"
  end

  def handle_action(player, action)
    case action
    when /h|H/ # hit (take a card)
      c = deal_one(player)
      puts "drew: #{c}, new count is #{player.count}"
    when /s|S/ # stand (end players turn)
      player.standing = true
      puts "standing with count #{player.count}"
    when /d|D/ # double (double wager, take a single card and finish)
      if player.bet(player.bet_amt)
        c = deal_one(player)
        puts "doubled and drew: #{c}, new count is #{player.count}, new bet is #{player.bet_amt}"
      else
        c = deal_one(player)
        puts "not enough funds, hit instead and drew: #{c}, new count is #{player.count}"
      end
    when /e|E/ # surrender (give up a half-bet and retire from the game)
      player.end_round((player.bet_amt * 0.5).to_i)
    end
  end

  # prompts a player for a single action
  def prompt_action(player, p_index)
    puts 'PROMPT ACTION'
    player.hands.each_index do |h_index|
      puts("Player #{p_index}, hand #{h_index}: #{player.hand_to_s} your count is #{player.count}")
      # if the player can split their hand, ask them if they want to.
      prompt_split(player, h_index) if player.can_split(h_index)

      action = prompt_for_action("On hand #{h_index}, what is your action? #{ACTION_HELP}")
      handle_action(player, action)
    end
  end

  # handles gameplay for a single round, prompting each player accordingly
  def play_round
    @players.each_with_index do |p, p_index|
      next if p.bust? || p.standing

      prompt_action(p, p_index)
      if p.bust?
        puts BUST_STR
        p.end_round(0)
      end
      puts ''
    end
  end

  # handles betting payouts once the hand is over
  def settle_bets
    @players.each_with_index do |player,  index|
      if player.bust? # bust players get nothing
        puts "Player #{index} was bust with count #{player.count}"
      elsif player.blackjack?
        win_amt = (player.bet_amt * 1.5).to_i
        player.end_round(player.bet_amt + win_amt) # blackack pays pot plus 3/2 bet
        puts "Player #{index} got blackjack and won #{win_amt} and now has cash #{player.cash}"
      elsif @dealer.bust? || player.count > @dealer.count
        win_amt = player.bet_amt
        player.end_round(player.bet_amt + win_amt) # normal win returns pot plus bet
        puts "Player #{index} won #{win_amt} and now has cash #{player.cash}"
      elsif player.count == @dealer.count
        player.end_round(player.bet_amt) # normal win returns pot plus bet
        puts "Player #{index} tied and now has cash #{player.cash}"
      else
        player.end_round(0)
        puts "Player #{index} lost #{player.bet_amt} and now has cash #{player.cash}"
      end
    end
  end

  # executes the standard dealer's strategy and then settles bets with players
  def run_dealer
    puts "Scoring Dealer...\n#{@dealer.hand_to_s}"
    loop do
      sleep 0.5
      break unless @dealer.will_hit
      deal_one(@dealer)
      puts "Count #{@dealer.count}: #{@dealer.hand_to_s}"
    end
    # print out dealers final status
    puts("Dealer #{@dealer.bust? ? 'bust' : 'standing'} with count #{@dealer.count}")
    settle_bets
  end

  # plays a single hand of gameplay, where each player is prompted in rounds
  # until they are all either bust or standing
  def play_hand
    @deck.build_deck # resets the deck for the next game
    initial_deal # deals two cards to each player
    initial_bets # prompts each player for their inital bets
    loop do
      play_round
      # end hand when all players are standing, either by choice or because they are bust
      break if @players.reduce(true) { |a, e| a && e.standing }
    end
    run_dealer
    @players.each { |p| p.reset }
    @dealer.reset
  end

  # reads command line input to handle gameplay
  def play
    puts START_STR
    hand_count = 1
    loop do
      puts "\nPLAYING HAND #{hand_count}\n"
      play_hand
      break unless prompt_for_yn("\nWould you like to play another hand?")
      hand_count += 1
    end
    puts 'Thanks for playing!'
  end

  # returns a string of each player's to_s concatenated
  def to_s
    str = 'GAME STATUS =>'
    @players.each_index do |i|
      str += "Player #{i}: #{@players[i]}, "
    end
    str.slice(0, str.length - 2) # removes final ', '
  end
end
