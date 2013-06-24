ACPC Poker Gui Client
======================
The [Annual Computer Poker Competition][ACPC homepage] Poker Gui Client provides a graphical user interface with which people may play poker games against automated agents. It is still under development, but currently supports two-player limit and no-limit Texas Hold'em, and has the potential to support three-player as well.

This application is built with *Ruby and Rails*.

More details
----------------
* [GitHub][ACPC Poker GUI Client GitHub] - Code
* [Documentation][documentation] - Documentation

Components
------------
Much of this application's functionality comes from component gems that began as part of this project and subsequently branched away to become stand-alone projects:

* [ACPC Dealer][ACPC Dealer GitHub] - Wraps the [<em>ACPC Dealer Server</em>][ACPC competition server] in a handy gem with a convenient runner class, and a script for compiling and running the dealer and example players.
* [ACPC Dealer Data][ACPC Dealer Data GitHub] - Utilities for extracting information from [<em>ACPC Dealer Server</em>][ACPC competition server] logs. Used for testing.
* [ACPC Poker Basic Proxy][ACPC Poker Basic Proxy GitHub] - Utilities for communicating with the [<em>ACPC Dealer Server</em>][ACPC competition server].
* [ACPC Poker Match State][ACPC Poker Match State GitHub] - Provides a manager for the state of a poker match.
* [ACPC Poker Player Proxy][ACPC Poker Player Proxy GitHub] - Provides a full proxy through which a match of poker may be played with the [<em>ACPC Dealer Server</em>][ACPC competition server]. Match states sent by the dealer are retrieved automatically whenever they are available, and are interpreted and managed for the user.
* [ACPC Poker Types][ACPC Poker Types] - Fundamental poker types like `Card`, `Player`, `GameDefinition`, and `MatchState`.

Prerequisites
----------------

* A compatible *\*NIX*-based operating system. Has been successfully installed on *Ubuntu 10.04.4 LTS*, *11.04*, *12.04*, and *Mac OS X Lion*. *Windows* is not supported (in this case, it is recommended to run a compatible operating system as a virtual machine in [VMWare Player](http://www.vmware.com/products/player/) or [VirtualBox](https://www.virtualbox.org/).
* Ruby 1.9.3 - This can be installed in different ways, but a good choice is [RVM][RVM homepage]. Or you can follow these [instructions][Ruby downloads] to install via a different method.
* Git - While this should only be required if you want to install Ruby via [RVM][RVM homepage], installing Git also makes working with this repository easier, so it is recommended. Follow these [instructions][Git setup] to do so.
* [Bundler][Bundler homepage] - Bundler is a Ruby gem that manages a project's gem dependencies. It requires zlib, which can be installed through [RVM][RVM homepage] by running
    
        rvm pkg install zlib
Once Ruby is installed, installing Bundler should only be a matter of running

        gem install bundler

* A non-LLVM version of GCC - This may require some extra steps on OSX as some versions of XCode no longer include such compilers. There are many [discussions on solutions for this on stack overflow](http://stackoverflow.com/questions/8032824/cant-install-ruby-under-lion-with-rvm-gcc-issues).
* For using the app, a modern non-*Internet Explorer* browser (*Google Chrome* or *Chromium* tend to work best and is most thoroughly tested with). Must support *JavaScript* and *websockets*, and both must be enabled. In theory, Internet Explorer should work properly but it (at least in this application) has a problem with the rails `remote: true` option for injecting *AJAX* into forms, and I'm not sure why or how to fix it.

Installation
---------------
Download [the code][ACPC Poker GUI Client GitHub], which can be done by running

    git clone git://github.com/dmorrill10/acpc_poker_gui_client.git

Next, download a [<em>MongoDB</em>][MongoDB downloads] version compatible with your system, unpack the compressed file to `<project root>/vendor`, and rename the resulting directory to `mongoDB`.

then, in the project's root directory, run

    bundle install
    bundle exec rake install

This should install most of the application's dependencies, except [<em>Apache</em>][Apache homepage], including gems, and will complete the MongoDB setup.


Non-gem dependencies
---------------------------
[<em>MongoDB</em>][MongoDB homepage] is used as the database back-end.

Web server
--------------
### Development mode
A `WEBrick` server packaged with `rails` serves the application locally in development mode.

### Production mode
An [<em>Apache server</em>][Apache homepage] hosts the application proper in production mode. This is currently done with Apache-Rails integration through [<em>Phusion Passenger</em>][Phusion Passenger homepage]. As [Apache][Apache homepage] is only used in production, it is not required to deploy this application on a local development server.

Deployment
------------

### Simple start
For convenience, there are two `rake` tasks that combine the two operations described below that are needed to start the app for different environments.

#### Development mode
Deploying the application in development mode on a `WEBrick` server is simply a matter of running

    bundle exec rake start_dev_server
in the project's root directory.

#### Production mode
Similarly, to deploy in production mode (given that [<em>Apache</em>][Apache homepage] and [<em>Phusion Passenger</em>][Phusion Passenger homepage] are properly configured), run:

    bundle exec rake start_prod_server

### More details
For the app to be deployed properly, three servers must be started:
1. The *MongoDB* database server `mongod`
2. The custom `em-websocket` server `lib/background/worker.rb`. This is a fairly simple Ruby script that listens for websocket connections from the app (all other foreign connection attempts are closed upon connection) and manages background processes necessary to play matches, such as `dealer`, opponent agent, and user proxy (which is an agent that connects to the dealer on the user's behalf and takes actions according to the user's directions from the app) instances.
3. A web server for Rails (see **Web server**).

The `god` script `config/god.rb` will start both `mongod` and `lib/background/worker.rb`. To run this, use the command (the `-l <log file>` logging option is optional but recommended)
        
    bundle exec god -c config/god.rb` -l log/god.log

After `god` is running, all that's left is to run a web server.

Updates
---------
Updating this application can be done by running

    bundle exec rake update
in the project's root directory, which will pull the newest down code from the [repository][ACPC Poker GUI Client GitHub] and install any missing gems.

These tasks can be done separately too (as can all rake tasks, see Rakefile for more details), with [Git][Git homepage] and [Bundler][Bundler homepage] commands.

CLI
------
`bin/acpc_cli_client` is a somewhat crude command line interface that allows users to start and participate in `dealer` hosted matches through the command line.

Generators
------------
This project includes custom generators:

* poker_bot
* scss_class

For execution details, run

    rails g <generator name> --help

For more information, see this [tutorial][Rails generators tutorial] on [_Rails_][Rails] generators.

Contributing
----------------------

### Issues
See the [issue tracker](https://github.com/dmorrill10/acpc_poker_gui_client/issues?state=open) for currently known issues, or to log new ones.

### Tests
Run `rspec` in the project's root directory to run its tests. When making changes to the code that you'd like to have pulled into this project, please be sure to add tests as best you can. 

### To contribute code
1. Fork this repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright
---------
Copyright &copy; 2011-2013 by the Computer Poker Research Group, University of Alberta. See [LICENSE](LICENSE.md) for details.

Further resources
------------------
* [Annual Computer Poker Competition][ACPC homepage]
* [Coffescript][Coffeescript homepage] - JavaScript in a candy coating. Used by default as of [Rails][Rails] 3.1 and used in this project's views.
* [Gem Bundler][Bundler homepage] - Gem dependency management tool used by this project.
* [GitHub][GitHub homepage] - Host for this project's code.
* [Git][Git homepage] - Version control system used by this project.
* [God process monitoring][God homepage] - Used to manage background processes in production.
* [Haml][Haml] - The template language used by this project's views.
* [Markdown][Markdown] - The formatting syntax used to write most of this project's non-code documentation.
* [MongoDB][MongoDB homepage] - The database back-end for this project.
* [Phusion Passenger][Phusion Passenger homepage] - Enables integration between [_Rails_][Rails] and [_Apache_][Apache homepage] in production.
* [Programming Ruby][Programming Ruby] - a tutorial on Ruby programming.
* [RDoc][RDoc] - The formatting syntax used to write some of this project's non-code documentation, when [Markdown][Markdown] is not enough.
* [RVM][RVM homepage] - Ruby installation and version manager.
* [Railscasts][Railscasts] - Ruby on Rails video tutorials.
* [Rake][Rake] - Ruby build program.
* [Ruby on Rails][Rails] - Web application framework used by this project.
* [RubyDoc.info][RubyDoc.info] - Documentation hosting site used by this project.
* [SASS][SASS] - Styling language extension of CSS used by default as of [Rails][Rails] 3.1 and is used in this project.
* [The Apache Project][Apache homepage] - The production web server used by this project.
* [The Computer Poker Research Group][CPRG homepage]
* [The Ruby Programming Language][Ruby] - The foundational language of this project.
* [University of Alberta][UAlberta homepage] - Host institution to the [Computer Poker Research Group][CPRG homepage].
* [YARD][YARD] - The documentation tool used by this project, which also defines tags used by in-code documentation.

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
[Rails generators tutorial]: http://guides.rubyonrails.org/generators.html
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