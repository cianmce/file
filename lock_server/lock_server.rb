require 'socket'
require 'thread'
require 'open-uri'
require 'pathname'
require 'json'


class Server
  def initialize(student_id)
    @student_id = student_id
    @local_ip = local_ip
    @remote_ip = open('http://whatismyip.akamai.com').read
    puts "remote_ip: #{@remote_ip}"


    # { "path/to/file.txt" => [waiting_sockets, waiting_sockets2] }
    @lock_hash = {}

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
              handle_request(work_q.pop, i)
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


  def handle_request(client, tid)
    data = client.gets
    puts "data:"
    p data
    unless data.nil?
      data = data.chomp # chomp to remove last \n
      puts "\t\tprocess_data[#{@tid}]: '#{data}'"
      process_data(data, client)
    end
  end

  def process_data(data, client)
    puts "processing '#{data}'"
    req = JSON.parse(data)

    allowed_methods = [
      "lock",
      "unlock"
    ]
    method = req['method']
    param  = req['param']
    puts "method: #{method}"
    if allowed_methods.include? method
      send(method, param, client)
    else
      invalid(data)
    end
  end

  def invalid(data, client)
    write_back("invalid command '#{data}'", 400, client)
  end

  def write_back(response, status, client)
    json_response = {"response"=>response, "status"=>status}.to_json
    puts "write_back:"
    p json_response
    client.puts "#{json_response}\n"
    client.close
  end

  def lock(param, client)
    path = param

    unless @lock_hash.include? path
      @lock_hash[path] = [] #waiting sockets
      write_back("locked: '#{path}'", 200, client)
      puts "@lock_hash:"
      p @lock_hash
      return
    end
    # already locked. Add socked to waiting list
    @lock_hash[path].push(client)
    puts "@lock_hash:"
    p @lock_hash
  end

  def unlock(param, client)
    path = param

    unless @lock_hash.include? path
      # File wasn't locked
      write_back("NOT locked: '#{path}'", 400, client)
      return
    end
    # send message 1st waiting client
    socket = @lock_hash[path].shift
    if @lock_hash[path].empty?
      # This was the last socket waiting. No locks on this file now
      @lock_hash.delete(path)
    end
    # Send msg to socket
    unless socket.nil?
      write_back("locked: '#{path}'", 200, socket)
    end
    write_back("UNlocked: '#{path}'", 200, client)

    puts "@lock_hash:"
    p @lock_hash
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

