require 'socket'
require 'thread'
require 'open-uri'
require 'pathname'

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
    threads = (0...max_threads).map do |i|
      puts "starting thread: #{i}"
      Thread.new do
        begin   
          while @running
            if work_q.length > 0
              client = work_q.pop
              handle_request(client)
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

  def ls(data, client)
    puts "doing directory listing"
    glue = "  "
    # Check for -l flag
    unless data.strip.scan(/\-\w*\l$/).empty?
      # Has -l flag
      glue = "\n"
    end

    # 
    files = [".","..","all","the","files.txt"]
    text = files.join(glue)

    client.puts text
    client.close
  end

  def cd(data, client)
    # check if given directory exists
    # Returns absolute path, i.e. removes "..", a/b/../c -> a/c & a/b/./c -> a/b/c
    # path = Pathname.new path
    # path = path.cleanpath

  end

  def handle_request(client)
    data = client.gets # Read 1st line from socket
    # data = client.read # Read all data
    puts "\t\thandle_request: '#{data}'"


    if data.start_with?("ls")
      # directory listing
      text = ls(data, client)
    elsif data.start_with?("HELO")
      text = helo(data, client)
    elsif data == "KILL_SERVICE\n"
      text = kill(data, client)
    else
      text = unknown_message(data, client)
    end
    # Force delay
    # sleep(0.5)
    client.puts text
    client.close
    if not @running
      exit
    end
  end
    
  # Handle old requests
  def helo(data, client)
    puts "received HELO"
    text = "#{data}IP:#{@remote_ip}\nPort:#{@port}\nStudentID:#{@student_id}\n"
    puts "returning: '#{text}'"
    return text
  end
  def unknown_message(data, client)
    text = "Unknown message[#{data.length}]: '#{data}'"
    puts text
    puts "returning: '#{text}'"
    return text
  end
  def kill(data, client)
    puts "Killing"
    @running = false
    @socket.close
    text = "Server closing\n"
    puts "returning: '#{text}'"
    return text
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

