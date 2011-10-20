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
end
