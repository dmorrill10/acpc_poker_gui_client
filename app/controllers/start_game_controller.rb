
require 'application_helper'

# Controller for the main web page view.
class StartGameController < ApplicationController
   include ApplicationHelper
   
   # Displays the main web page view.
   def index
      respond_to do |format|
         format.html {}
         format.js do
            replace_page_contents 'start_game/index'
         end
      end
   end
end
