
# Provides classes with an easy way of defining exceptions at the
# top of a class.
class Class
   # Make the string conform to the naming convention of a class
   def to_class_name(characters)
      class_name = characters.to_s.capitalize
      class_name.gsub(/[_\s]+./) { |match| match = match[1,].capitalize }
   end
   
   # Create new exception classes.
   def exceptions(*names)
      names.each do |name|
         error_name = to_class_name name
         const_set(error_name, Class.new(RuntimeError))
      end
   end
end
