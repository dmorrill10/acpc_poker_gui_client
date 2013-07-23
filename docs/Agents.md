Adding Agents
================
After completing one set of the below instructions for registering an agent and restarting your server, your bot should be available to select in the match start dropdown, and it should be playable.

By ACPC-Style Script
---------
Simply provide an agent name and run path to a program that takes a dealer host name and port number, in that order, in [`bots/bots.rb`](../bots/bots.rb) under all the game definitions that your agent can play.

By Ruby Object and Dynamic Command Builder
----------------
This method allows greater freedom on how and what arguments are provided to your agent, but it takes a few extra steps and requires some knowledge of Ruby:

1. Copy the Ruby class [`bots/run_testing_bot.rb`](../bots/run_testing_bot.rb) and rename it `bots/run_your_agent.rb`, where `your_agent` is the name of your bot. Open this file and customize its contents for your agent.
2. Add an entry for your class to [`bots/bots.rb`](../bots/bots.rb) as described in that file.