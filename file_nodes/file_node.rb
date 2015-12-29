require 'socket'
require 'pathname'
require 'json'
# Make dirs
require 'fileutils'



class FileNode

  def initialize(socket, tid, port, node_type)
    @node_type = node_type
    @tid = tid
    @port = port
    @start_file_node_write_port = 6000
    @start_file_node_read_port  = 7000
    @socket = socket

    @base_dir = "#{Dir.pwd}/files/#{@node_type}_node_#{@port}"
    FileUtils.mkdir_p(@base_dir)
    puts "made: #{@base_dir}"

    puts "initialized [#{node_type}] on port: #{@port}"
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

  def process_data(data)
    puts "processing '#{data}'"
    req = JSON.parse(data)

    allowed_methods = [
      "ls",
      "write",
      "mkdir",
      "read",
      "rm",
      "exists",
    ]
    method = req['method']
    param  = req['param']
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
    @socket.puts "#{json_response}\n"
  end

  def read(filename)
    path = "#{@base_dir}/#{filename}"

    f = File.open(path,"r")
    contents = f.read()
    f.close()

    puts "contents: '#{contents}'"
    write_back(contents, 200)
  end

  def write(param)
    filename = param[0]
    contents = param[1]
    # 'a' or 'w'
    mode     = param[2] || 'w'
    path = "#{@base_dir}/#{filename}"

    # Ensure directory exists
    directory_full_path = path.split('/')[0..-2].join('/')
    FileUtils.mkdir_p(directory_full_path)

    f = File.open(path, mode)
    size = f.write(contents)
    f.close()

    if @node_type=='primary'
      port =  @port.to_i+1000
      puts "sending write to slave: #{port}"

      file_node_socket = TCPSocket.open('localhost', port)
      res = make_request('write', [filename, contents, mode], file_node_socket)
      file_node_socket.close
      puts "sent to slave"

    end

    puts "Writen to #{path}"
    write_back(size, 200)
  end

  def mkdir(directory)
    if directory[0]=='/'
      directory.slice!('/')
    end
    path = "#{@base_dir}/#{directory}"
    puts "making: #{path}"
    FileUtils.mkdir_p(path)

    if @node_type=='primary'
      port =  @port.to_i+1000
      puts "sending mkdir to slave: #{port}"

      file_node_socket = TCPSocket.open('localhost', port)
      response = make_request('mkdir', directory, file_node_socket)
      file_node_socket.close

      puts "sent to slave"

    end

    write_back("done", 200)
  end

  def rm(path)
    # This acts the same as rm -rf
    if path[0]=='/'
      path.slice!('/')
    end
    path = "#{@base_dir}/#{path}"
    puts "deleting: #{path}"
    FileUtils.rm_rf(path)
    write_back("done", 200)
  end

  def exists(param)
    path = param[0]
    type = param[1] || "file"

    found = false

    path = @base_dir+path

    puts "checking if '#{path}' is a #{type}"

    if type=="file"
      found = File.file?(path)
    else
      found = File.directory?(path)
    end
    if found
      puts "#{path} is a #{type}"
      write_back("", 204)
      return
    end
    puts "#{path} is NOT a #{type}"
    write_back("#{type}: '#{path}' not found", 404)
  end

  def ls(directory)
    if directory[0]=='/'
      directory.slice!('/')
    end
    path = "#{@base_dir}/#{directory}"
    unless path[-1]=="/"
      path += '/'
    end
    puts "path: #{path}"
    # Remove '.' and '..'
    begin
      entries = Dir.entries(path)  
    rescue Errno::ENOENT => e
      write_back("path does not exist", 404)
      return
    end
    contents = entries.reject{ |e| e[0]=='.' }
    # if dir add '/'
    contents.map! do |content|
      puts "checking if '#{path+content}' is a dir"
      if File.directory?(path+content)
        content+'/'
      else
        content
      end
    end
    puts "contents"
    p contents
    write_back(contents, 200)
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
