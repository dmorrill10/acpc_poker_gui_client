Landing page
~   should show a new match form so a person can start a new match.
    - new match form
    ~   should refuse requests to create matches that lack a name, game def, opponents, the number of hands, or seat
    ~   should show a list of game definitions and a default
    ~   should show lists of possible opponents depending on game def choice and the number of lists depends on the game def choice as well (one for each player in the game besides the user) and a default
    ~   should allow the user to specify a number of hands and provide a default
    ~   should show a list of possible seats or random (which should also be the default)
    ~   should allow the optional specification of a random seed, defaulting to a random random seed
    ~   should proceed to the loading page upon successful request
~   should show a join match form so more than one person can play in a match.
    - join match form
    ~   should refuse requests to join matches that lack a name or seat
    ~   should show a list of match names in which the user could join
    ~   should show a list of seats in which the user could join the match (depends on the match choice)
    ~   should proceed to the loading page upon successful request
~   should show a rejoin match form so a person can rejoin a match previously started.
    - rejoin match form
    ~   should refuse requests to rejoin matches that have already been rejoined
    ~   should refuse requests to rejoin matches that lack a name or seat
    ~   should show a list of match names in which the user could rejoin
    ~   should show a list of seats in which the user could rejoin the match (depends on the match choice)
~   should show a spectate match form
    - spectate match form
    ~   should show a list of match names that could be spectated
~   should show a footer
    - footer
    ~   should show a report issues link to github
    ~   should show copyright info
~   should show a header toolbar
    - header toolbar
    ~   should show the app name
    ~   should show the user name
    ~   should show a link to help documentation

Loading page
~   should continue showing the header toolbar
~   should continue showing the footer
~   should show a message requesting patience from the user
~   should proceed to the table page upon successful request

Table page
~   should show a header toolbar
    - header toolbar
    ~   should show the app name
    ~   should show the user name
    ~   should show a link to help documentation
    ~   should show dropdown hotkeys menu
        - hotkeys menu
        ~   should show the list of hotkey bindings
        ~   should show a customize button
            - customize hotkeys
            ~   should be a modal dialog
            ~   should refuse requests to set two functions to the same key
            ~   should allow players to specify new keys to default functions
            ~   should allow players to add a pot fraction bet function and assign a key to it
            ~   should allow players to add another custom pot fraction bet function
            ~   should allow players to unbind functions by assigning no key to them
            ~   should allow players to remove custom pot fraction bet functions from the list by unbinding them
            ~   should show all keys in uppercase
            ~   should provide a save button
            ~   should provide a cancel button
            ~   should allow players to reset their keys to defaults
    ~   should show a leave match button
        - leave match button
        ~   should prompt the user and ask if they're sure they want to leave
