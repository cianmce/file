require 'socket'
require 'thread'
require 'open-uri'
require 'pathname'
require 'json'
require_relative 'client'


class Server
  def initialize(student_id)
    @student_id = student_id
    @local_ip = local_ip
    @remote_ip = open('http://whatismyip.akamai.com').read
    puts "remote_ip: #{@remote_ip}"
    puts 'initialized'
  end

  def run(port_number, max_threads, host='0.0.0.0')
    @running = true
    @port = port_number
    work_q = Queue.new
    @socket = TCPServer.new(host, port_number)

    puts "listening on #{@remote_ip}:#{port_number}"    

    # Starts server
    Thread.abort_on_exception = true
    threads = (0...max_threads).map do |i|
      puts "starting thread: #{i}"
      Thread.new do
        begin   
          while @running
            if work_q.length > 0
              client = Client.new(work_q.pop, i)
              client.serve
              puts "Closing client[#{i}]"
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

