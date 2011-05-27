#!/usr/bin/env ruby
#
# fhpipe - watches southern cad call directories for closed
# calls and pipes them to firehouse cad_monitor

require 'rubygems'
require 'eventmachine'
require 'em-dir-watcher'

# some simple config
port = 7799
host = "localhost"
logfile = "C:\\fhpipe_log\\pd.log"
datapath = "D:\\firehouse"

module Client
  def post_init
    @log = File.open(logfile, 'a')

    dir = (ARGV.empty? ? datapath : ARGV.shift)
    #dir = (ARGV.empty? ? '.' : ARGV.shift)
    inclusions = ARGV.reject { |arg| arg =~ /^!/ }
    inclusions = nil if inclusions == []
    exclusions = ARGV.select { |arg| arg =~ /^!/ }.collect { |arg| arg[1..-1] }
    

    dw = EMDirWatcher.watch dir, :include_only => inclusions, :exclude => exclusions do |paths|
      paths.each do |path|
        full_path = File.join(dir, path)
        if File.exists? full_path
          @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] SENDING #{path}\n")
          # windows fix, send_file_data failboats on win32
          file = File.open(path, 'r') 
          send_data "#{path}>"
          file.each_line {|line| send_data line}  
        end
      end
    end

    @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] MONITORING #{File.expand_path(dir)}...\n")
  end

  def receive_data(data)
    @log.write(data) 
    #puts data
    #close_connection_after_writing
  end

  def unbind
    @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] CONNECTION TERMINATED\n")
    EventMachine::stop_event_loop
  end
end


EM.error_handler{ |e|
  @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] Error raised during event loop: #{e.class.name} #{e.message}\n")
  puts e.backtrace
}

EventMachine::run {
  EventMachine::connect host, port, Client
}
