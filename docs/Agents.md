Adding Agents
================

When adding agents to play against, there are three tasks to do:

1. Ensure that your agent, or a script wrapper around your agent exists that can be run by providing a port number and (optionally) a `dealer` host name, e.g.

    ./your_agent <port number> [host name]
Or

    ssh your_agent <port number> [host name]

2. Copy the Ruby class `bots/run_testing_bot.rb` and rename it `bots/run_your_agent.rb`, where `your_agent` is the name of your agent. Open this file and customize its contents for your bot.
3. Add an entry to `bots/bots.rb` as described in that file.

After restarting your server, the your bot should then be available to select in the match start dropdown, and should be playable.