# Copyright 2014 Aaron M. Taylor

require './game_objects.rb'
require './strings.rb'

# utility method that retrieves a number from command line input
# repeatedly prompts if the given input is invalid for conversion
def prompt_for_num(prompt)
  puts prompt
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
  puts "#{prompt} [y/n]"
  loop do
    response = STDIN.gets.chomp
    return true if response.match(/y|Y/)
    return false if response.match(/n|N/)
    puts 'invalid response, please try again'
  end
end

##################################################
# A command line blackjack game
##################################################
class Blackjack
  attr_accessor :deck

  def initialize(num_players = 4)
    @dealer = Player.new(true)
    @players = []
    num_players.times do |_i|
      @players << Player.new
    end
    @deck = Deck.new
  end

  def deal_one(player)
    c = @deck.draw
    player.take(c)
    c
  end

  # deals each player two cards to start off the round
  def initial_deal
    @players.each do |p|
      deal_one(p)
      deal_one(p)
    end
  end

  def play_round
    @players.each_index do |index|
      p = @players[index]
      next if p.bust?

      puts "Player #{index}: #{p.hand_to_s}"
      hit = prompt_for_yn("Your count is #{p.count}, would you like to hit?")
      if hit
        puts "drew: #{deal_one(p)}, new count is #{p.count}\n\n"
        puts BUST_STR if p.bust?
      else
        p.stay
      end
    end
  end

  def play_hand
    initial_deal
    loop do
      play_round
      # end hand when all players are bust for now
      # TODO: add stay behavior to players
      break if @players.reduce(true) { |a, e| a && e.bust? }
    end
    @players.each { |p| p.reset_cards }
    @deck.build_deck
  end

  def to_s
    str = 'GAME STATUS =>'
    @players.each_index do |i|
      str += " Player #{i}: #{@players[i]},"
    end
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
