require 'socket'
require 'pathname'
require 'json'

require 'yaml'


class Client
  def initialize(socket, id)
    config = YAML.load_file(File.dirname(__FILE__)+'/../config/config.yml')
    
    @lock_server_port = config['LOCK_SERVER_PORT']
    @directory_server_port = config['DIRECTORY_SERVER_PORT']
    @socket = socket
    @id = id
    @current_directory = "/"

    puts "initialized"
  end

  def serve
    puts "serving"
    while !@socket.closed?
      puts "waiting in [#{@id}]"
      data = @socket.gets
      p @socket.closed?
      if data.nil? # client closed
        break
      end
      data = data.chomp # chomp to remove last \n
      if data.start_with?"exit"
        write_back("Closing Client[#{@id}]", 200)
        break
      end
      puts "\t\thandle_request[#{@id}]: '#{data}'"
      process_data(data)
      sleep(0.05)
    end
    puts "socket closed!!"
  end

  def process_data(data)
    puts "processing '#{data}'"
    if data.start_with?("ls")
      ls(data)
    elsif data.start_with?("pwd")
      pwd(data)
    elsif data.start_with?("cd")
      cd(data)
    elsif data.start_with?("mkdir")
      mkdir(data)
    elsif data.start_with?("read") || data.start_with?("cat")
      read_file(data)
    elsif data.start_with?("write")
      write_file(data)
    elsif data.start_with?("rm")
      remove(data)
    elsif data.start_with?("help")
      help(data)
    else
      invalid(data)
    end
  end

  def invalid(data)
    write_back("invalid command '#{data}'", 400)
  end

  def help(data)
    text = "\nls [-l]: directory listing. -l to list vertically\n"
    text += "pwd: print working directory\n"
    text += "cd <directory>: change directory\n"
    text += "mkdir <directory>: make directory\n"
    text += "read/cat <file>: view contents of a file\n"
    text += "write <file> [-a] \"<contents of file>\": write to a file. -a appends to a file, \\n and \\t add new lines and tabs\n"
    text += "rm [-rf]: remove files or directories. -rf to remove directory and all contents\n"
    text += "exit: close client connection\n"
    text += "help: view help\n\n\n"
    write_back(text, 200)
  end

  def write_back(response, status)
    json_response = {"response"=>response, "status"=>status}.to_json
    @socket.puts "#{json_response}\n"
  end

  def read_file(data)
    if data.start_with?("read")
      data.slice!("read")
    elsif data.start_with?("cat")
      data.slice!("cat")
    end

    directory = data.strip
    puts "reading: '#{directory}'"
    path = Pathname.new @current_directory + directory
    path = path.cleanpath
    puts "path: #{path}"

    # get port for 'path'
    res = lookup(path, 'read', 'file')
    p res
    if res['status'] >= 300
      write_back("not found", 404)
      return
    end

    ports, path = res['response']
    port = ports[0]
    puts "port: #{port}"

    # read path from file_server on 'port'

    file_node_socket = TCPSocket.open('localhost', port)
    res = make_request('read', path, file_node_socket)
    file_node_socket.close
    p res
    if res['status'] >= 300
      write_back("error reading file", 404)
      return
    end

    contents = res['response']

    write_back(contents, 200)
  end

  def write_file(data)
    # e.g.
    # data = "write file.txt -a \"some contents\nmore here\""
    # write aa -a "some stuff\nnew lineszz\n\n\nmore\n\tsome tabz\nend :)\n"
    # write abc/1.txt -a "\n\nI am 1"

    data = data.split('"')

    command = data[0]
    command = command.split(' ')
    file_path = command[1]
    if command[2] == '-a'
      puts 'append'
      mode = 'a'
    else
      mode = 'w'
    end
    contents = data[1].gsub('\\n', "\n").gsub('\\t', "\t")


    puts "writing: '#{file_path}'"
    puts "contents: '#{contents}'"
    path = Pathname.new @current_directory + file_path
    path = path.cleanpath
    puts "path: #{path}"

    # get port for 'path'
    res = lookup(path, 'write', 'file')
    p res
    if res['status'] >= 300
      write_back("not found", 404)
      return
    end

    ports, path = res['response']
    port = ports[0]
    puts "port: #{port}"

    # Lock the file
    puts "Trying to lock '#{path}'"
    lock_socket = TCPSocket.open('localhost', @lock_server_port)
    res = make_request('lock', path, lock_socket)
    lock_socket.close
    puts "lock res:"
    p res


    # write to path from file_server on 'port'

    file_node_socket = TCPSocket.open('localhost', port)
    res = make_request('write', [path, contents, mode], file_node_socket)
    file_node_socket.close

    p res
    if res['status'] >= 300
      write_back("error reading file", 404)
      return
    end
    size = res['response']

    # Simulate a long time to write
    puts "Sleeping 2..."
    sleep(2)
    puts "awake"

    # unlock file
    lock_socket = TCPSocket.open('localhost', @lock_server_port)
    res = make_request('unlock', path, lock_socket)
    lock_socket.close
    puts "unlock res:"
    p res

    write_back(size, 200)
  end

  def remove(data)
    # e.g.
    # rm some/file.txt
    # rm -rf some/file.txt

    data = data.split(' ')

    if data[1]=="-rf" || data[1]=="-fr"
      type = 'dir'
    else
      type = 'file'
    end

    file_path = data[-1]

    puts "writing: '#{file_path}'"
    path = Pathname.new @current_directory + file_path
    path = path.cleanpath
    puts "path: #{path}"

    # get port for 'path'
    res = lookup(path, 'read', type)
    p res
    if res['status'] >= 300
      write_back("not found", 404)
      return
    end

    ports, path = res['response']
    port = ports[0]
    puts "port: #{port}"

    # write to path from file_server on 'port'

    file_node_socket = TCPSocket.open('localhost', port)
    res = make_request('rm', path, file_node_socket)
    file_node_socket.close

    p res
    if res['status'] >= 300
      write_back("error reading file", 404)
      return
    end

    status = res['response']

    write_back(status, 200)
  end


  def ls(data)
    puts "doing directory listing"
    glue = "  "
    # Check for -l flag
    unless data.strip.scan(/\-\w*\l/).empty?
      # Has -l flag
      glue = "\n"
    end

    # Get listing
    puts "getting node with current_directory: #{@current_directory}"
    res = lookup(@current_directory, 'read', 'dir')
    p res

    if res['status'] >= 300
      write_back("not found", 404)
      return
    end

    ports = res['response'][0]

    files = []
    ports.each do |port|
      puts "Getting listing for port: #{port}"
      file_node_socket = TCPSocket.open('localhost', port)
      puts "ls-ing directory: #{@current_directory}"
      res = make_request('ls', @current_directory, file_node_socket)
      file_node_socket.close
    
      puts "res:"
      p res
      if res['status'] >= 300
        write_back("error getting listing: #{res['response']}", 404)
        return
      end
      files.push(res['response'])
      p files
    end
    p files
    text = files.join(glue)
    write_back(text, 200)
  end

  def pwd(data)
    write_back(@current_directory, 200)
  end

  def cd(data)
    # check if given directory exists on appropriate node
    # Returns absolute path, i.e. removes "..", a/b/../c -> a/c & a/b/./c -> a/b/c
    # path = Pathname.new path
    # path = path.cleanpath

    # Get directory
    data.slice!("cd")
    directory = data.strip
    puts "Changing directory to: '#{directory}'"
    path = Pathname.new @current_directory + directory
    path = path.cleanpath
    puts "path: #{path}"

    # Check directory exists
    # Lookup in directory server
    puts "checking if #{path}"
    res = lookup(path, 'read', 'dir')
    p res
    if res['status'] >= 300
      p "no such directory: '#{path}'"
      write_back("no such directory: '#{path}'", 404)
      return
    end
    puts "good"


    # Save current directory
    @current_directory = path
    puts "dir changed"
    write_back(@current_directory, 200)
  end

  def mkdir(data)
    # check if given directory exists on appropriate node
    # Returns absolute path, i.e. removes "..", a/b/../c -> a/c & a/b/./c -> a/b/c
    # path = Pathname.new path
    # path = path.cleanpath

    # Get directory
    data.slice!("mkdir")
    directory = data.strip
    puts "making dir: '#{directory}'"
    path = Pathname.new @current_directory + directory
    path = path.cleanpath
    puts "path: #{path}"

    # Check directory exists
    # Lookup in directory server
    puts "getting port for '#{path}'"
    res = lookup(path, 'write', 'dir')

    ports, path = res['response']
    port = ports[0]
    puts "making dir in port: #{port}"

    file_node_socket = TCPSocket.open('localhost', port)
    response = make_request('mkdir', path, file_node_socket)
    file_node_socket.close
    
    puts 'response:'
    p response
    

    # Save current directory
    puts "dir created"
    write_back("created", 201)
  end

  def lookup(path, mode='write', type="file")
    puts "looking up: #{path}"
    # Open socket to directory server
    directory_socket = TCPSocket.open('localhost', @directory_server_port)
    response = make_request('lookup', [path, mode, type], directory_socket)
    directory_socket.close
    return response
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
