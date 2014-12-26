# Copyright 2014 Aaron M. Taylor

# scripting code to initialize gameplay is at the bottom of this file
# `play` method in Blackjack class is the entry point for gameplay

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
    puts 'invalid response, please try again'
  end
end

##################################################
# A command line blackjack game
##################################################
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
    player.count! # uses the sideeffects to modify aces if necessary
    c
  end

  # deals each player two cards to begin the hand
  def initial_deal
    @players.each do |p|
      deal_one(p)
      deal_one(p)
    end
    deal_one(@dealer)
    deal_one(@dealer)
  end

  # prompts each player for their initial bets for this hand
  def initial_bets
    puts 'INITIAL BETS:'
    @players.each_index do |index|
      p = @players[index]
      bet = prompt_for_num("Player #{index}: #{p.hand_to_s}, your count is #{p.count} and you have #{p.cash}. What is you initial bet?")
      puts "Player #{index} does not have enough funds, betting 0" unless p.bet(bet)
    end
    puts ''
  end

  # prompts a player for a single action
  def prompt_action(player)
    case prompt_for_action('What is your action? hit (h), stand (s), double (d), surrender (e)')
    when /h|H/ # hit (take a card)
      puts "drew: #{deal_one(player)}, new count is #{player.count}"
    when /s|S/ # stand (end players turn)
      player.standing = true
      puts "standing with count #{player.count}"
    when /d|D/ # double (double wager, take a single card and finish)
      if player.bet(player.bet_amt)
        puts "doubled and drew: #{deal_one(player)}, new count is #{player.count}, new bet is #{player.bet_amt}"
      else
        puts "not enough funds, hit instead and drew: #{deal_one(player)}, new count is #{player.count}"
      end
    when /e|E/ # surrender (give up a half-bet and retire from the game)
      player.end_round(player.bet_amt / 2)
    end
  end

  # handles gameplay for a single round, prompting each player accordingly
  def play_round
    @players.each_with_index do |p, index|
      next if p.bust? || p.standing

      puts("Player #{index}: #{p.hand_to_s} your count is #{p.count}")
      prompt_action(p)
      if p.bust?
        puts BUST_STR
        p.end_round(0)
      end
      puts ''
    end
  end

  def run_dealer
    puts "Scoring Dealer...\n#{@dealer.hand_to_s}"
    loop do
      sleep 0.5
      break unless @dealer.will_hit
      deal_one(@dealer)
      puts @dealer.hand_to_s
    end
    # print out dealers final status
    puts("Dealer #{@dealer.bust? ? 'bust' : 'standing'} with count #{@dealer.count}")
  end

  def settle_bets
    @players.each_with_index do |player,  index|
      if player.bust? # bust players get nothing
        puts "Player #{index} was bust with count #{player.count}"
      elsif player.blackjack?
        win_amt = (player.bet_amt * 1.5).to_i
        player.end_round(player.bet_amt + win_amt) # blackack pays pot plus 3/2 bet
        puts "Player #{index} got blackjack and won #{win_amt} and now has cash #{player.cash}"
      elsif player.count < @dealer.count
        win_amt = player.bet_amt
        player.end_round(player.bet_amt + win_amt) # normal win returns pot plus bet
        puts "Player #{index} won #{win_amt} and now has cash #{player.cash}"
      elsif player.count == @dealer.count
        player.end_round(player.bet_amt) # normal win returns pot plus bet
        puts "Player #{index} tied and now has cash #{player.cash}"
      end
    end
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
    settle_bets
    @players.each { |p| p.reset }
  end

  # reads command line input to handle gameplay
  def play
    puts START_STR
    hand_count = 1
    loop do
      puts "\nPLAYING HAND #{hand_count}\n"
      play_hand
      break unless prompt_for_yn('Would you like to play another hand?')
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

###########################################################
# Scripting code to setup the game and initialize play
###########################################################

puts BLACKJACK_TITLE

# retrieves the count
num_players = prompt_for_num(PLAYER_COUNT_PROMPT)

# creates a new blackjack game with the user-specificed number of players
game = Blackjack.new(num_players)

# begins gameplay with an interpreter loop inside the Blackjack class
game.play
