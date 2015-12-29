require 'socket'
require 'thread'
require 'open-uri'
require 'pathname'
require 'json'
require_relative 'file_node'


class Server
  def initialize
    @local_ip = local_ip
    @remote_ip = open('http://whatismyip.akamai.com').read
    puts "remote_ip: #{@remote_ip}"
    puts 'initialized'
  end

  def run(port_number, max_threads, node_type, host='0.0.0.0')
    @node_type = node_type
    @running = true
    @port = port_number
    work_q = Queue.new
    @socket = TCPServer.new(host, port_number)

    puts "listening on #{@remote_ip}:#{port_number} - #{@node_type}"    

    # Starts server
    Thread.abort_on_exception = true
    threads = (0...max_threads).map do |i|
      puts "starting thread: #{i}"
      Thread.new do
        begin   
          while @running
            if work_q.length > 0
              file_node = FileNode.new(work_q.pop, i, port_number, node_type)
              file_node.serve
              puts "Closing directory[#{i}]"
            else
              sleep(0.05)
            end
          end
        rescue ThreadError
          puts 'oopps ThreadError...'
          puts ThreadError
        end
      end
    end;
    puts 'all threads started'
    while @running
      begin
        work_q.push(@socket.accept)
      rescue IOError
        # Socket closed by kill function
        puts 'Closed'
      end
    end

    # Wait for threads to join
    threads.map(&:join)
    puts 'Byeee :)'
  end
  
  def local_ip
    orig = Socket.do_not_reverse_lookup  
    Socket.do_not_reverse_lookup = true # turn off reverse DNS resolution temporarily
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1 # googles ip
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end

