# Copyright 2014 Aaron M. Taylor

require './game_objects.rb'
require './strings.rb'

################################
# utility methods that retrieve values from command line input
# these methods ask repeatedly is input is invalid
################################

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
# `play` method is the entry point for command-line user interactions
#
# `initial_deal` and `initial_bets` setup each game appropriately
# `play_game` and `play_round` perform movement through the basic gameplay
# `prompt_action` performs the majority of user interactions
# `run_dealer` and the settle methods appropriately reward players who have won
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

  # helps determine when the game should be scored
  def all_players_finished
    @players.reduce(true) { |a, e| a && (e.standing || e.all_bust?) }
  end

  #########################################
  # Start of game
  #########################################

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
      # only one hand exists for the initial round of betting
      h = p[0]
      bet = prompt_for_num("Player #{index}: #{h}, your count is #{h.count} and you have #{p.cash}. What is your initial bet?")
      puts "Player #{index} does not have enough funds, betting 0" unless p.bet(bet)
    end
    puts ''
  end

  #########################################
  # End of game
  #########################################

  def settle_single_bet(player, hand)
    if player.all_bust? # bust players get nothing
      puts "was bust with count #{player.count}"
    elsif hand.blackjack?
      win_amt = (hand.bet * 1.5).to_i
      player.end_round(hand.bet + win_amt) # blackack pays pot plus 3/2 bet
      puts "got blackjack and won #{win_amt} and now has cash #{player.cash}"
    elsif @dealer.all_bust? || hand.count > @dealer.count
      win_amt = hand.bet
      player.end_round(hand.bet + win_amt) # normal win returns pot plus bet
      puts "won #{win_amt} and now has cash #{player.cash}"
    elsif hand.count == @dealer.count
      player.end_round(hand.bet) # tie returns pot
      puts "tied and now has cash #{player.cash}"
    else # player had valid hand but lost
      player.end_round(0)
      puts "lost #{player.bet_amt} and now has cash #{player.cash}"
    end
  end

  # handles betting payouts once the hand is over
  def settle_bets
    @players.each_with_index do |player,  p_index|
      # allows for puts if the player had no remaining hands
      standing_hands = false
      player.hands.each_with_index do |hand, h_index|
        print "Player #{p_index}, hand #{h_index}, "
        settle_single_bet(player, hand)
        standing_hands = true
      end
      print "Player #{p_index} was bust and now has cash #{player.cash}" unless standing_hands
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
    puts("Dealer #{@dealer.all_bust? ? 'bust' : 'standing'} with count #{@dealer.count}")
    settle_bets
  end

  #########################################
  # Regular gameplay
  #########################################

  # propmts the player for a split if one is possible
  def prompt_split(player, h_index)
    return unless prompt_for_yn("Would you like to split hand #{h_index}?")
    player.split(h_index)
    puts "hand #{h_index} is now: #{player[h_index]} with count #{player[h_index].count}"
  end

  # handles the user's inputted action for the given hand
  def handle_action(action, player, h_index)
    case action
    # hit (take a card)
    when /h|H/
      c = deal_one(player)
      puts "drew: #{c}, new count is #{player[h_index].count}"
    # stand (end players turn)
    when /s|S/
      player.standing = true
      puts "standing with count #{player[h_index].count}"
    # double (double wager, take a single card and finish)
    when /d|D/
      if player.bet(player[h_index].bet, h_index)
        c = deal_one(player)
        puts "doubled and drew: #{c}, new count is #{player[h_index].count}, new bet is #{player[h_index].bet}"
      else
        c = deal_one(player)
        puts "not enough funds, hit instead and drew: #{c}, new count is #{player.count}"
      end
    # surrender (give up a half-bet and retire from the game)
    when /e|E/
      player.end_round((player.bet_amt * 0.5).to_i)
    end
  end

  # prompts a player for an action for each of their hands
  def prompt_action(player)
    player.hands.each_with_index do |hand, h_index|
      puts hand
      # if the hand is standing, leave it alone
      puts "hand #{h_index} is standing" if hand.standing
      next if hand.standing

      puts("on hand #{h_index}: #{hand} your count is #{hand.count}")
      # if the player can split their hand, ask them if they want to.
      prompt_split(player, h_index) if player.can_split(h_index)

      handle_action(prompt_for_action("On hand #{h_index}, what is your action? #{ACTION_HELP}"), player, h_index)
    end
    # gets rid of bust hands
    player.clean_hands
  end

  # handles gameplay for a single round, prompting each player accordingly
  def play_round
    @players.each_with_index do |p, p_index|
      next if p.all_bust? || p.standing

      puts "Player #{p_index}:"
      prompt_action(p)
      if p.all_bust?
        puts BUST_STR
        p.end_round(0)
      end
      puts ''
    end
  end

  # plays a single game where each player is prompted in rounds for their action
  # until they are all either bust or standing
  def play_game
    @deck.build_deck # resets the deck for the next game
    initial_deal # deals two cards to each player
    initial_bets # prompts each player for their inital bets
    loop do
      play_round
      # end hand when all players are standing, either by choice or because they are bust
      break if all_players_finished
    end
    run_dealer
    @players.each { |p| p.reset }
    @dealer.reset
  end

  # top-level loop that handles multiple hands of gameplay
  def play
    puts START_STR
    game_count = 1
    loop do
      puts "\n+++++++++++++++++++++++++++++++++++++++++++++++++++"
      puts "PLAYING HAND #{game_count}\n"
      play_game
      break unless prompt_for_yn("\nWould you like to play another hand?")
      game_count += 1
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
