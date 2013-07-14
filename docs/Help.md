Help
====

Initial interface
----------------
Upon arriving at the application landing site or refreshing the application's page, tabbed forms will be presented that will allow you to start a new match, join a match started by another user, or rejoin a match you had previously left.

Your user name will be displayed in the top right of the page in the toolbar. This defaults to `Guest` when no authentication information is provided.

To the left of your user name, you will find a help icon. Clicking it will send you to this page.

Clicking on the application name on the far left of the toolbar will return you to the application landing page.

Entering a match
------------------------------
Fill in the appropriate fields in one of the forms on the application landing page, then press the corresponding submit button. If you are starting or joining a match, you will have to wait until the other players (both human and robotic) connect before starting the match and seeing the table. Depending on the agents you are playing against, this could take a minute or two, so please be patient and do not refresh the page. If it takes longer than ten minutes, please log an issue [here](https://github.com/dmorrill10/acpc_poker_gui_client/issues/new) detailing your exact situation (date and time, system and browser, match setup, and your observations). Rejoining a match, on the other hand should be very fast since all players had connected previously.

Game interface
------------------------
Added to the toolbar will be two new buttons labeled (from left to right) `Hotkeys` and `Leave Match`. Pressing the `Leave Match` button will ask you to confirm that you'd like to leave the match (the match can be rejoined from the application landing page at any time for a week after the last time you acted in the match).

### Hotkeys
Clicking `Hotkeys` will reveal a drop down menu listing your currently set hotkeys. At the bottom of the menu, you will find a `Customize` link. Clicking this will present a dialog that will allow you to change your hotkeys. Only simple one key hotkeys are supported, and no two hotkeys may be assigned the same key. Leaving a hotkey blank will cause no change. Hotkeys are persisted across matches for every user, so users need only customize them once.

- Press the `Save` button at the bottom of the form to save your changes. 
- Press the `Cancel` button, the `x` button in the top right of the window, hit the `Esc` on your keyboard, or click outside of the menu to cancel your changes and return to the table. 
- Press the `Reset to Default` button at the bottom of the form to return your hotkeys to their original values. 

### Match information
A box in the upper left of the interface will show the match name, the current hand number, the total number of hands in this match, and the player balances.