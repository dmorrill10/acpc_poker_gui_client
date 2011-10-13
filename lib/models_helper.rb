require 'application_defs'

# Assortment of static helper methods for models and model tests.
module ModelsHelper
   include ApplicationDefs

   # Flatten a given array into a single element if there is only one element in the array.
   # That is, if the given array is a single element array, it returns that element,
   # otherwise it returns the array.
   #
   # @param [Array] array The array to flatten into a single element.
   # @return +array+ if +array+ has more than one element, the single element in +array+ otherwise.
   def flatten_if_single_element_array(array)
      log "flatten_if_single_element_array"
      
      if 1 == array.length then array[0] else array end
   end

   # Loops over every line in the file corresponding to the given file name.
   #
   # @param [String] file_name The name of the file to loop through.
   # @yield Block to operate on +line+.
   # @yieldparam [String] line A line from the file corresponding to +file_name+.
   # @raise [Errno::ENOENT] Unable to open or read +file_name+ error.
   def for_every_line_in_file(file_name)
      begin
         file = File.new file_name, "r"
      rescue
         raise "Unable to open #{file_name}"
      else
         log "Opened file #{file_name}"
         
         begin
            while line = file.gets do
               line.chomp!
               
               log "Read #{line} from #{file_name}"
               
               yield line
            end
         rescue
            raise "Unable to read #{file_name}"
         end
      ensure
         file.close if file
      end
   end

   # Checks if the given line is a comment beginning with '#' or ';', or empty.
   #
   # @param [String] line
   # @return [Boolean] True if +line+ is a comment or empty, false otherwise.
   def line_is_comment_or_empty?(line)
      log "line_is_comment_or_empty?"
      
      !line.match(/^\s*[#;]/).nil? or line.empty?
   end
   
   # @param [Integer] integer_rank The integer ACPC representation of the card's rank.
   # @param [Integer] integer_suit The integer ACPC representation of the card's suit.
   # @return [Integer] The integer ACPC representation of the card.
   def make_acpc_card(integer_rank, integer_suit)
      integer_rank * CARD_SUITS.length + integer_suit
   end
   
   # @param [String] string_card A card represented by a string of the form
   #  '<rank><suit>'
   # @return [Integer] The numeric ACPC representation of the card.
   def to_acpc_card_from_card_string(string_card)
      string_rank = string_card[0]
      string_suit = string_card[1]
      
      integer_rank = CARD_RANK_NUMBERS[string_rank]
      integer_suit = CARD_SUIT_NUMBERS[string_suit]
            
      make_acpc_card(integer_rank, integer_suit)
   end
end
