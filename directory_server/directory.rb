
require 'socket'
require 'pathname'
require 'json'

require 'yaml'

class Directory

  def initialize(socket, id)
    config = YAML.load_file(File.dirname(__FILE__)+'/../config/config.yml')
    
    @num_file_nodes = config['NUM_FILE_NODES']
    @start_file_node_write_port = config['START_FILE_NODE_WRITE_PORT']
    @start_file_node_read_port  = config['START_FILE_NODE_READ_PORT']
    @socket = socket
    @id = id
    @ranges = shard_ranges(@num_file_nodes)
    @current_directory = "/"
    puts "ranges: "
    p @ranges
    puts "initialized"
  end

  def serve
    puts "serving"
    puts "waiting in [#{@tid}]"
    data = @socket.gets
    puts "data:"
    p data
    unless data.nil?
      data = data.chomp # chomp to remove last \n
      if data.start_with?"exit"
        write_back("Closing Socket[#{@tid}]", 200)
        return
      end
      puts "\t\tprocess_data[#{@tid}]: '#{data}'"
      process_data(data)
    end
  end

  def shard_ranges(num_nodes)
    # Returns the letter ranges for n nodes
    # n < 26
    max_nodes = 26
    if num_nodes >= max_nodes
      num_nodes = max_nodes
    end
    shard_size = (26/num_nodes).to_i
    ranges = []
    num_nodes.times do |i|
      start_i = (i*shard_size)
      end_i   = ((i+1)*shard_size)
      if i==num_nodes-1
        end_i = max_nodes
      end
      end_i -= 1

      start_letter = (start_i + 'a'.ord).chr
      end_letter = (end_i + 'a'.ord).chr
      ranges.push [start_i, end_i]
    end
    return ranges
  end

  def get_node(path)
    s = path.dup
    s.downcase!
    if s[0]=="/"
      c = s[1]
    else
      c = s[0]
    end
    p @ranges
    p s
    p c
    n = c.ord - 'a'.ord
    @ranges.each_with_index do |range, index|
      p index
      p range
      if n <= range[1]
        return index
      end
    end
    return @ranges.size - 1
  end

  def process_data(data)
    puts "processing '#{data}'"
    req = JSON.parse(data)

    allowed_methods = [
      "lookup"
    ]
    method = req['method']
    param  = req['param']
    puts "method: #{method}"
    if allowed_methods.include? method
      send(method, param)
    else
      invalid(data)
    end
  end

  def invalid(data)
    write_back("invalid command '#{data}'", 400)
  end

  def write_back(response, status)
    json_response = {"response"=>response, "status"=>status}.to_json
    puts "write_back:"
    p json_response
    @socket.puts "#{json_response}\n"
  end

  def lookup(param)
    # Returns the port of the server to access or 404
    # for read, the file/directory MUST exist
    # for write it doesn't need to exist
    path = param[0]
    mode = param[1]
    type = param[2] # dir or file

    if path=="/" && mode=="read"
      # ls on '/' base dir
      # return all ports
      ports = []
      (0..@num_file_nodes-1).each do |node_id|
        port = @start_file_node_read_port + node_id
        # port = @start_file_node_write_port + node_id
        ports.push(port)
      end
      write_back([ports, path], 200)
      return
    end

    puts "Path: #{path}"

    node_id = get_node(path)
    puts "Node: #{node_id}"
    port = 0

    if mode=="read"
      # Check if exists
      port = @start_file_node_read_port + node_id
      # port = @start_file_node_write_port + node_id

      puts "Connecting to port: #{port}, checking if '#{path}' is '#{type}' - #{mode}"
      file_node_socket = TCPSocket.open('localhost', port)
      res = make_request('exists', [path, type], file_node_socket)
      file_node_socket.close
      if res['status'] >= 300
        write_back(res['response'], res['status'])
        return
      end
    else
      mode = 'write'
      port = @start_file_node_write_port + node_id
    end
    write_back([[port], path], 200)
  end

  def make_request(method, param, socket)
    payload = {
      "method" => method,
      "param" => param
    }.to_json
    puts "payload: '#{payload}'"
    socket.puts "#{payload}\n"
    response = socket.gets
    p response
    r = JSON.parse(response)
    p r
  end
end




