Exhibition App
==============
The *Active Match Table* must
- show all active matches
- have a button associated with each match
    - rejoin if it is the user's match
    - spectate otherwise
- update for all users whenever
    - a match is started,
    - a match is finished,
    - a hand finishes.

What are the connection breaking conditions?
- Web server death
    - Arbitrary restriction on match lifespan. How long should a match be rejoinable?
- Server machine shutdown
    - The `dealer` instance is killed and there's currently no way of restoring matches to a particular hand. This could maybe happen if the random seeds for bots were specified by the app and matches were "replayed" to the shutdown point.
- Browser crash
    - Arbitrary restriction on match lifespan. How long should a match be rejoinable?
- Network problem
    - Arbitrary restriction on match lifespan. How long should a match be rejoinable?
- Leave Match button
    - Kills match
- Close browser
    - Kills match


Landing Page
------------

### Active Match Table

Given the user is on the landing page,
the user must see a table listing all currently active matches (*Active Match Table*).

Given the user is on the landing page,
when a match has been initialized but before it has been started,
its entry in Active Match Table must show
    1. the user associated,
    2. an active spectate button if the user is not playing in the match or an inactive button otherwise

Given the user is on the landing page,
when a match has been initialized and after it has been started,
its entry in Active Match Table must show
    1. the user associated,
    2. an active spectate button if the user is not playing in the match or an inactive button otherwise
    3. the ratio of completed hands

Given the user is on the landing page,
when a match is started by any user including itself,
the user's Active Match Table must update.

Given the user is on the landing page,
when a hand is finished by any user,
the user's Active Match Table must update.

Given the user is on the landing page,
when a match is finished any user,
the user's Active Match Table must update.


Match Table
-----------

### Timeout

Given the user is playing in a match,
when the user fails to act within 60 seconds,
then
    1. A pop-up must tell the user that they have been timed out
    2. The user must be returned to the landing page

Given the user is playing in a match,
the user must see a countdown of the time remaining to play before timeout.

The user timeout must be shorter than the actual match lifespan.





When will a match be considered complete and ended?
---------------------------------------------------
- When the browser tab is closed
- When the user leaves the match through the "Leave Match" function
- When the user times out


What are the possible points of failure in the app?
---------------------------------------------------
- Insufficient data is transfered from browser to the server to continue
- Insufficient data is present in the session to continue
- A process cannot be started in the background
- A process in the background dies
- Data is deleted before it should be
- The server is overloaded and can no longer respond properly


---
I want a method that goes from the client to the server, but web apps aren't organized like that. They transition based on user interaction or messages from the realtime server.
---


General App
===========

Landing page
~   must show a new match form so a person can start a new match.
    - new match form
    ~   must refuse requests to create matches that lack a name, game def, opponents, the number of hands, or seat
    ~   must show a list of game definitions and a default
    ~   must show lists of possible opponents depending on game def choice and the number of lists depends on the game def choice as well (one for each player in the game besides the user) and a default
    ~   must allow the user to specify a number of hands and provide a default
    ~   must show a list of possible seats or random (which must also be the default)
    ~   must allow the optional specification of a random seed, defaulting to a random random seed
    ~   must proceed to the loading page upon successful request
~   must show a join match form so more than one person can play in a match.
    - join match form
    ~   must refuse requests to join matches that lack a name or seat
    ~   must show a list of match names in which the user could join
    ~   must show a list of seats in which the user could join the match (depends on the match choice)
    ~   must proceed to the loading page upon successful request
~   must show a rejoin match form so a person can rejoin a match previously started.
    - rejoin match form
    ~   must refuse requests to rejoin matches that have already been rejoined
    ~   must refuse requests to rejoin matches that lack a name or seat
    ~   must show a list of match names in which the user could rejoin
    ~   must show a list of seats in which the user could rejoin the match (depends on the match choice)
~   must show a spectate match form
    - spectate match form
    ~   must show a list of match names that could be spectated
~   must show a footer
    - footer
    ~   must show a report issues link to github
    ~   must show copyright info
~   must show a header toolbar
    - header toolbar
    ~   must show the app name
    ~   must show the user name
    ~   must show a link to help documentation

Loading page
~   must continue showing the header toolbar
~   must continue showing the footer
~   must show a message requesting patience from the user
~   must proceed to the table page upon successful request

Table page
~   must show a header toolbar
    - header toolbar
    ~   must show the app name
    ~   must show the user name
    ~   must show a link to help documentation
    ~   must show dropdown hotkeys menu
        - hotkeys menu
        ~   must show the list of hotkey bindings
        ~   must show a customize button
            - customize hotkeys
            ~   must be a modal dialog
            ~   must refuse requests to set two functions to the same key
            ~   must allow players to specify new keys to default functions
            ~   must allow players to add a pot fraction bet function and assign a key to it
            ~   must allow players to add another custom pot fraction bet function
            ~   must allow players to unbind functions by assigning no key to them
            ~   must allow players to remove custom pot fraction bet functions from the list by unbinding them
            ~   must show all keys in uppercase
            ~   must provide a save button
            ~   must provide a cancel button
            ~   must allow players to reset their keys to defaults
    ~   must show a leave match button
        - leave match button
        ~   must prompt the user and ask if they're sure they want to leave
