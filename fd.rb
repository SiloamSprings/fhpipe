#!/usr/bin/env ruby
#
# fhpipe - watches southern cad call directories for closed
# calls and pipes them to firehouse cad_monitor

require 'rubygems'
require 'eventmachine'

# some simple config
port = 7799
host = "localhost"
logfile = "C:\\fhpipe_log\\fd.log"
cad_incoming = "C:\\cad_incoming\\"

module EchoServer

  def post_init
    @log = File.open(logfile, 'a')
    @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] CONNECTION ESTABLISHED\n")
  end

  def receive_data data
    send_data "-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] DATA RECEIVED BY SERVER\n"

    filename = data.split('>')[0]
    filedata = data.split('>')[1]
    
    @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] INCOMING DATA\n")
    @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] WRITING TO FILENAME: #{filename}\n")

    # DEBUG
    # puts filedata
    File.open(cad_incoming+filename, 'a') {|f| f.write(cad_incoming+filedata) } unless File.exists?(cad_incoming+filename)

    @log.write("\n-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] WRITE COMPLETE\n")
  end

  def unbind
    @log.write("-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] CONNECTION TERMINATED\n")
  end
end

EventMachine::run {
  puts "-- [#{Time.now.strftime("%H:%M:%S %d%b%Y").upcase}] LISTENING ON PORT #{port}"
  EventMachine::start_server host, port, EchoServer
}
