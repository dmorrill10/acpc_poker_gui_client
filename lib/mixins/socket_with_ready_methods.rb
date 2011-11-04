
# Mixin to add methods to IO so that they will also be inherited by TCPSocket.
class IO
   # Checks if the socket is ready to be read from.
   # @return [Boolean] +true+ if the socket is ready to be read from, +false+ otherwise.
   def ready_to_read?
      read_array = [self]
      write_array = nil
      error_array = nil
      timeout = 1
      
      IO.select(read_array, write_array, error_array, timeout) != nil
   end
   
   # Checks if the socket is ready to be written to.
   # @return [Boolean] +true+ if the socket is ready to be written to, +false+ otherwise.
   def ready_to_write?
      read_array = nil
      write_array = [self]
      error_array = nil
      timeout = 1
      
      IO.select(read_array, write_array, error_array, timeout) != nil
   end   
end
