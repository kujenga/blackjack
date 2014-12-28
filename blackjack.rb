# Copyright 2014 Aaron M. Taylor

require './game_objects.rb'
require './strings.rb'

################################
# utility methods that retrieve values from command line input
# these methods ask repeatedly is input is invalid
################################

# repeatedly prompts if the given input is invalid for conversion
def prompt_for_num(prompt, limit = 1_000_000)
  puts(prompt + ' ')
  loop do
    print CL_PROMPT
    begin
      i = Integer(STDIN.gets.chomp) # throws an error for invalid numbers
      if i > limit || i <= 0
        puts(i <= 0 ? 'Number must be greater than zero' : "Too high, please enter a number #{limit} or lower")
        next
      end
      return i
    rescue ArgumentError
      puts 'Please enter a valid number'
    end
  end
end

# utility method for retrieving a y/n answer from command line input
def prompt_for_yn(prompt)
  puts "#{prompt} [y/n] "
  loop do
    print CL_PROMPT
    response = STDIN.gets.chomp
    return true if response.match(/y|Y/)
    return false if response.match(/n|N/)
    puts 'invalid response, please try again'
  end
end

# black-jack specific utility method for retrieving player action from command line input
def prompt_for_action(prompt)
  puts(prompt + ' ')
  loop do
    print CL_PROMPT
    response = STDIN.gets.chomp
    # hit, stand, double, surrender
    return response if response.match(/h|H|s|S|d|D|e|E/)
    puts 'invalid response, please try again '
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

  def initialize
    @dealer = Dealer.new(true)
    @deck = Deck.new
  end

  # deals a single card to the passed in player, then returns that card
  def deal_one(player, h_index  = 0)
    c = @deck.draw
    player.take(c, h_index)
    puts BUST_STR if player[h_index].bust?
    c
  end

  # helps determine when the game should be scored
  def all_players_finished
    @players.reduce(true) do |acc, player|
      acc && player.finished?
    end
  end

  #########################################
  # Start of game
  #########################################

  def initialize_players
    # retrieves the count
    num_players = prompt_for_num(PLAYER_COUNT_PROMPT, 10)
    @players = []
    num_players.times do |_i|
      @players << Player.new
    end
  end

  # deals each player two cards to begin the hand
  def initial_deal
    @players.each do |p|
      # p.take(deal_one(p), 0) # only for testing split behavior
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
      puts "Player #{index} does not have enough funds, betting 0" unless p.bet(bet, 0)
    end
    puts ''
  end

  #########################################
  # End of game
  #########################################

  def settle_single_bet(player, hand)
    if hand.surrendered
      print "was surrendered with count #{hand.count}"
    elsif hand.bust? # bust hands get nothing
      print "was bust with count #{hand.count}"
    elsif hand.blackjack?
      win_amt = (hand.bet * 1.5).to_i
      player.return_winnings(hand.bet + win_amt) # blackack pays pot plus 3/2 bet
      print "got blackjack and won #{win_amt}"
    elsif @dealer.bust? || hand.count > @dealer.count
      win_amt = hand.bet
      player.return_winnings(hand.bet + win_amt) # normal win returns pot plus bet
      print "won #{win_amt}"
    elsif hand.count == @dealer.count
      player.return_winnings(hand.bet) # tie returns pot
      print 'tied'
    else # player had valid hand but lost
      print "lost #{hand.bet}"
    end
    puts " and now has cash #{player.cash}"
  end

  # handles betting payouts once the hand is over
  def settle_bets
    @players.each_with_index do |player,  p_index|
      # allows for puts if the player had no remaining hands
      player.hands.each_with_index do |hand, h_index|
        print "Player #{p_index}, hand #{h_index}, "
        settle_single_bet(player, hand)
      end
    end
  end

  # executes the standard dealer's strategy and then settles bets with players
  def run_dealer
    sleep 0.5
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

  #########################################
  # Regular gameplay
  #########################################

  # propmts the player for a split if one is possible
  def prompt_split(player, h_index)
    return unless prompt_for_yn("Would you like to split hand #{h_index}?")
    player.split(h_index)
    puts "After split, hand #{h_index} is: #{player[h_index]} with count #{player[h_index].count}"
  end

  # handles the user's inputted action for the given hand
  def handle_action(action, player, h_index)
    case action
    # hit (take a card)
    when /h|H/
      c = deal_one(player, h_index)
      puts "drew: #{c}, new count is #{player[h_index].count}"
    # stand (end players turn)
    when /s|S/
      player[h_index].standing = true
      puts "standing with count #{player[h_index].count}"
    # double (double wager, take a single card and finish)
    when /d|D/
      if player.bet(player[h_index].bet, h_index)
        c = deal_one(player, h_index)
        puts "doubled and drew: #{c}, new count is #{player[h_index].count}, new bet is #{player[h_index].bet}"
      else
        c = deal_one(player, h_index)
        puts "not enough funds, hit instead and drew: #{c}, new count is #{player[h_index].count}"
      end
    # surrender (give up a half-bet and retire from the game)
    when /e|E/
      # settles and deletes the hand from the player
      player.return_winnings((player[h_index].bet * 0.5).to_i)
      player[h_index].surrendered = true
    end
  end

  # prompts a player for an action for each of their hands
  def prompt_action(player)
    player.hands.each_with_index do |hand, h_index|
      # if the hand is standing, leave it alone
      puts "hand #{h_index} is #{hand.status}" if hand.out?
      next if hand.out?

      puts("On hand #{h_index}: #{hand} your count is #{hand.count}")
      # if the player can split their hand, ask them if they want to.
      prompt_split(player, h_index) if player.can_split(h_index)

      handle_action(prompt_for_action("What is your action? #{ACTION_HELP}"), player, h_index)
    end
  end

  # handles gameplay for a single round, prompting each player accordingly
  def play_round
    @players.each_with_index do |p, p_index|
      next if p.finished?
      puts "Player #{p_index}, cash #{p.cash}:"
      prompt_action(p)
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
    initialize_players
    puts START_STR
    game_count = 1
    loop do
      puts "\n+++++++++++++++++++++++++++++++++++++++++++++++++++" if game_count > 1
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
