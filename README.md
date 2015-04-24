# Blackjack
#### Created by Aaron Taylor

[![Coverage Status](https://coveralls.io/repos/kujenga/blackjack/badge.svg)](https://coveralls.io/r/kujenga/blackjack)

A command line game implemented in Ruby

To get started, enter `./run.rb` in the command line

### How to play
The program prompts the player for the necessary actions each hand, asking for initial bets and then presenting the standard options of hit, stand, double, split, and surrender.

Aces are handled by defaulting to a high value, and if the player goes over they are used as low.

========================

## Changes

I added a line to display the dealers single face-up card at the beginning of the game. This information gives players a basis for their actions as the round progresses and is crucial to estimating odds that the dealer will bust.

I fixed an issue where the `splittable` method on the `Hand` class was checking for actual card equality rather than value equality. In blackjack, any time a hand consists of a pair of cards of equal value, it can be split.

I also added more realistic handling of the deck based on what actual casinos do, where the dealer draws from a multideck made up of of 6 full decks that is kept through ten rounds of play, then reset.

I added unit tests for the game objects to ensure that everything was working as it should be. The tests can be run on their own, or in the `run.rb` script by specifying a 'test' argument from the command line
