class ApplicationController < ActionController::Base
   protect_from_forgery
   helper :layout

   # TODO Still needed?
   #def respond_with_js
   #   proc {
   #      respond_to do |format|
   #         format.js
   #      end
   #   }
   #end

   # TODO FOUND http://www.ruby-forum.com/topic/168406
   # TODO Still needed?
   #def redirect_to(options = {}, response_status = {})
   #   if request.xhr?
   #      render(:update) {|page| page.redirect_to(options)}
   #   else
   #      super(options, response_status)
   #   end
   #end

end
