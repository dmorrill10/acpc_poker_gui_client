
# @todo needed for socket mixin
require 'acpc_poker_basic_proxy'

# Class to run other processes.
class ProcessRunner
   @@pipes = []
   
   def self.kill_process
      begin
         pid = Process.wait
      rescue Errno::ECHILD
         # This occurs when there is no process to be killed by Process.wait
         # but if there is no process to kill then this method's job is done,
         # so do nothing here and return.
         return
      end
      
      puts "Child pid #{pid}: terminated"
      puts "trap: @@pipes: #{@@pipes.inspect}"
      pipes_to_close = @@pipes.select  { |pipe| !pipe.closed? && pid == pipe.pid }
      unless pipes_to_close.empty?
         pipe_to_close = pipes_to_close[0]
         puts "trap: pipe_to_close: #{pipe_to_close.inspect}"
         pipe_to_close.close
         @@pipes.delete pipe_to_close
      end
   end
   
   trap "CLD", Proc.new { ProcessRunner.kill_process }
   
   # Starts a process according to the given +command+.
   # @param [String] command The command to run.
   # @raise (see IO#popen)
   def initialize(command)
      begin
         @pipe = IO.popen(command)
      rescue
         raise
      end
      @@pipes << @pipe
      
      puts "initialize: @@pipes: #{@@pipes.inspect}"
   end
   
   # @return [String] A string from the process if there is one to be read and
   #  an empty string otherwise.
   # @raise (see IO#gets)
   def gets
      if @pipe.ready_to_read?
         begin
            @pipe.gets
         rescue
            raise
         end
      else
         ''
      end
   end
end
