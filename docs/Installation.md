Installation
===========

Vagrant (still experimental but potentially *much* easier. I recommend trying this first.)
----------------
Install [*Vagrant*](http://www.vagrantup.com/) for your system and run `vagrant up` in the root directory of this project. This will download and boot a virtual machine, then install the necessary packages to be compatible with this project. Once the virtual machine has started successfully, 

1. ssh into it (see these [instructions](http://docs.vagrantup.com/v2/getting-started/up.html) for more details on how to do this), 
2. clone this project again to your home directory (the share folder is unusably slow so either clone the project again from Github, or copy it from the shared `/vagrant` directory), 
3. run `bundle install`, and finally 
4. `./script/start_dev_server` to get the app running.

The app should then be available on `http:localhost:3000`.

Manual
-------------

### Prerequisites

* A compatible *\*NIX*-based operating system. Has been successfully installed on *Ubuntu 10.04.4 LTS*, *11.04*, *12.04*, and *Mac OS X Lion*. *Windows* is not supported (in this case, it is recommended to run a compatible operating system as a virtual machine in [VMWare Player](http://www.vmware.com/products/player/) or [VirtualBox](https://www.virtualbox.org/).
* Ruby 2.0.0 - This can be installed in different ways, but a good choice is [RVM][RVM homepage]. Or you can follow these [instructions][Ruby downloads] to install via a different method.
* Git - While this should only be required if you want to install Ruby via [RVM][RVM homepage], installing Git also makes working with this repository easier, so it is recommended. Follow these [instructions][Git setup] to do so.
* [Bundler][Bundler homepage] - Bundler is a Ruby gem that manages a project's gem dependencies. It requires zlib, which can be installed through [RVM][RVM homepage] by running
    
        rvm pkg install zlib
Once Ruby is installed, installing Bundler should only be a matter of running

        gem install bundler

* A non-LLVM version of GCC - This may require some extra steps on OSX as some versions of XCode no longer include such compilers. There are many [discussions on solutions for this on stack overflow](http://stackoverflow.com/questions/8032824/cant-install-ruby-under-lion-with-rvm-gcc-issues).
* Redis - Background process server. See these [instructions](http://redis.io/topics/quickstart) for details on how to install.
* For using the app, a modern browser (*Google Chrome* or *Chromium* tend to work best and is most thoroughly tested). Must support and have *JavaScript* enabled.

### Installing the Project
Download [the code][ACPC Poker GUI Client GitHub], which can be done by running

    git clone git://github.com/dmorrill10/acpc_poker_gui_client.git

Next, download a [<em>MongoDB</em>][MongoDB downloads] version compatible with your system, unpack the compressed file to `<project root>/vendor`, and rename the resulting directory to `mongoDB`.

then, in the project's root directory, run

    bundle install
    bundle exec rake install

This should install most of the application's dependencies, except [<em>Apache</em>][Apache homepage], including gems, and will complete the MongoDB setup.


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