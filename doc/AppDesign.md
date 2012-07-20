
Application Design
====================

Abstract Design
-----------------

### Interface to the User

As this is a web application, the browser is the only interface between the _user_ and the application.


#### Participating in Matches

Users may participate in matches, so users:

* May _host_ a match by creating a _table_ and invite other users and/or select _bots_ to participate
    * Must inform all _participants_ of the ports that they must to use to connect to the <em>ACPC Dealer</em>
    * Must provide the dealer's match parameters to the other _competitors_ at the table.
* May accept invitations to matches hosted by other competitors
    * This application must be informed of the host name and port number it must use to connect to the dealer
* May leave the table at any time
    * All background processes related to the match that was exited must end and the dealer must exit
    * The other participants must be informed that the match has ended abruptly
* Must be notified of the end of the match
* Must see the result of a match they have played through
* May play matches consisting of at least one hand
* Must see the current state of the match

In addition, the web application must know what the dealer's match parameters are.

#### Playing Hands

Users may participate in matches so they may play hands. Therefore, users:

* May see the dealer's match parameters
* May take legal poker actions in the game (call, check, bet, raise, and fold)
    * Only those actions that are legal to take will be available for the user to take
    * May specify the size of the bet or raise, if the game allows variable size wagers
* Must be notified of the end of the hand
* Must see the result of a hand they have played through

### Starting Bots

If the number of users set to participate in a match is less than the number of
players in the selected game, the host user must specify enough bots to play
in the match as required for the game.
Bots:

* Must be informed of the dealer's match parameters

### Keeping Track of the User's <em>Match State</em>

The user's current match state will be recorded in a database table accessible
from both the web application and game logic.

The web application

* Must create the database table and fill it with the dealer's match parameters

The game logic

* Must connect to the dealer
* Must be run as a background process, since it must a connection to the dealer across web application requests
* May read the dealer's match parameters from the database
* Must send actions to the dealer upon request from the web application
* Must receive match state strings from the dealer when they are available
* Must record the current match state when a new match state string is received from the dealer

Implementation Details
------------------------

### Application Control Flow

When the user's browser is directed to the address of this application, a request is sent to Rails, which looks in `config/routes.rb` for `root :to => 'new_game#index'`. This routes the application's root address to the `index` _action_ of `NewGameController`.  Control moves into the `index` method of `NewGameController`.  When it drops out of `index`, Rails implicitly renders a _template_ with the same name in the `new_game` directory: `index.html.haml`, in this case.  This template sets up the application's page and renders the <em>partial template</em>, `_index.html.haml`.  `_index.html.haml` presents the initial form to the user.

### Match Control Flow

To start a match, the web application starts an instance of the dealer and any autonomous agents (commonly called bots) that the user has selected to play against. Bots are started as background processes on the Beanstalkd server.

To communicate to the dealer on the user's behalf, a `WebApplicationPlayerProxy` is started like the dealer and opponent bots themselves through the `stalker` gem and the `lib/background/worker.rb` script that it runs. The `WebApplicationPlayerProxy` shares match state information with the Rails controllers and views  through a `MongoDB` database `Match` model. The `mongoid` gem is used to interact with `MongoDB` on behalf of the application.

`WebApplicationPlayerProxy` utilizes the `acpc_poker_player_proxy` gem to handle the actual communication with the dealer and the management of the match's state. `WebApplicationPlayerProxy`'s' only responsibilities are to then package the data from the `PlayerProxy` instance into a `MatchSlice` model (embedded in the initial `Match` model), for `PlayerActionsController` to retrieve and display, and tell the `PlayerProxy` to send an action from the user (through `PlayerActionsController`) to the dealer.
