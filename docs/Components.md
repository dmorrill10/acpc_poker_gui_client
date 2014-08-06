Components
===============
Much of this application's functionality comes from component gems that began as part of this project and subsequently branched away to become stand-alone projects:

* [ACPC Dealer][ACPC Dealer GitHub] - Wraps the [<em>ACPC Dealer Server</em>][ACPC competition server] in a handy gem with a convenient runner class, and a script for compiling and running the dealer and example players.
* [ACPC Dealer Data][ACPC Dealer Data GitHub] - Utilities for extracting information from [<em>ACPC Dealer Server</em>][ACPC competition server] logs. Used for testing.
* [ACPC Poker Basic Proxy][ACPC Poker Basic Proxy GitHub] - Utilities for communicating with the [<em>ACPC Dealer Server</em>][ACPC competition server].
* [ACPC Poker Match State][ACPC Poker Match State GitHub] - Provides a manager for the state of a poker match.
* [ACPC Poker Player Proxy][ACPC Poker Player Proxy GitHub] - Provides a full proxy through which a match of poker may be played with the [<em>ACPC Dealer Server</em>][ACPC competition server]. Match states sent by the dealer are retrieved automatically whenever they are available, and are interpreted and managed for the user.
* [ACPC Poker Types][ACPC Poker Types] - Fundamental poker types like `Card`, `Player`, `GameDefinition`, and `MatchState`.

Non-gem dependencies
======================
[<em>MongoDB</em>][MongoDB homepage] is used as the database back-end and [Redis](http://redis.io/) for background processing.

Web server
============
## Development mode
A `Thin` server packaged with `rails` serves the application locally in development mode (though if the installation of the `thin` gem has problems, simply remove that line from the `Gemfile` and the default `WEBrick` server will be used instead).

## Production mode
An [<em>Apache server</em>][Apache homepage] hosts the application proper in production mode. This is currently done with Apache-Rails integration through [<em>Phusion Passenger</em>][Phusion Passenger homepage]. As [Apache][Apache homepage] is only used in production, it is not required to deploy this application on a local development server.

<!---
    Link references
    ================
-->
<!---
    General
-->

[ACPC competition server]: http://www.computerpokercompetition.org/index.php?option=com_rokdownloads&view=folder&Itemid=59
[ACPC homepage]: http://www.computerpokercompetition.org
[Apache homepage]: http://www.apache.org/
[Bundler homepage]: http://gembundler.com/
[CPRG homepage]: http://poker.cs.ualberta.ca/
[Coffeescript homepage]: http://coffeescript.org/
[Git homepage]: http://git-scm.com/
[Git setup]: https://help.github.com/articles/set-up-git#platform-all
[GitHub homepage]: https://github.com
[God homepage]: http://godrb.com/
[Haml]: http://haml.info/
[Markdown]: http://daringfireball.net/projects/markdown/
[MongoDB downloads]: http://www.mongodb.org/downloads
[MongoDB homepage]: http://www.mongodb.org/
[Phusion Passenger homepage]: http://www.modrails.com/
[Programming Ruby]: http://www.ruby-doc.org/docs/ProgrammingRuby/
[RDoc]: http://rdoc.sourceforge.net/
[RVM homepage]: https://rvm.io//
[Rails]: http://rubyonrails.org/
[Railscasts]: http://railscasts.com/
[Rake]: http://docs.rubyrake.org/
[Ruby]: http://www.ruby-lang.org/en/
[Ruby downloads]: http://www.ruby-lang.org/en/downloads/
[RubyDoc.info]: http://rubydoc.info/
[SASS]: http://sass-lang.com/
[UAlberta homepage]: http://www.ualberta.ca/
[YARD]: http://yardoc.org/

<!---
    Project specific
-->

[ACPC Dealer Data GitHub]: https://github.com/dmorrill10/acpc_dealer_data#readme
[ACPC Dealer GitHub]: https://github.com/dmorrill10/acpc_dealer#readme
[ACPC Poker Basic Proxy GitHub]: https://github.com/dmorrill10/acpc_poker_basic_proxy#readme
[ACPC Poker GUI Client GitHub]: https://github.com/dmorrill10/acpc_poker_gui_client
[ACPC Poker Match State GitHub]: https://github.com/dmorrill10/acpc_poker_match_state#readme
[ACPC Poker Player Proxy GitHub]: https://github.com/dmorrill10/acpc_poker_player_proxy#readme
[ACPC Poker Types]: https://github.com/dmorrill10/acpc_poker_types#readme
[documentation]: http://rubydoc.info/github/dmorrill10/acpc_poker_gui_client/master/frames