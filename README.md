ACPC Poker Gui Client
======================
The [Annual Computer Poker Competition][ACPC homepage] Poker Gui Client provides a graphical user interface with which people may play poker games against automated agents. It supports two-player and three-player limit and no-limit Texas Hold'em, as well as three-player Kuhn. It can support any game supported by the [ACPC Dealer][ACPC competition server] as well.

This application is built with *Ruby and Rails* and *Node.js*.

More details
----------------
* [Code on GitHub][ACPC Poker GUI Client GitHub]
* [Documentation][documentation]
* [Installation](docs/Installation.md)
* [Adding agents](docs/Agents.md)
* [User Help](docs/Help.md)
* [Components](docs/Components.md)

Deployment
------------
### Simple Start in Development Mode
Run `script/start_dev_server` and point a browser to `http:localhost:3000`.

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


Credit and Copyright
--------------------
Copyright &copy; 2011-2015 [Dustin Morrill](https://github.com/dmorrill10/). See [LICENSE](docs/LICENSE.md) for details.
Chip background and table felt images by [Nicholas Morrill](http://imakethingspretty.ca/), licensed under [Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/).

Developed with support from [Dr. Duane Szafron](http://webdocs.cs.ualberta.ca/~duane/), [Dr. Michael Bowling](http://webdocs.cs.ualberta.ca/~bowling/), [Natural Sciences and Engineering Research Council of Canada (NSERC)][NSERC], and the [Annual Computer Poker Competition][ACPC homepage].


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
[NSERC]: http://www.nserc-crsng.gc.ca/
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