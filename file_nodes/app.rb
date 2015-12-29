require_relative 'file_server'

require 'yaml'
config = YAML.load_file(File.dirname(__FILE__)+'/../config/config.yml')

MAX_THREADS  = config['MAX_THREADS']
default_port = config['START_FILE_NODE_WRITE_PORT']
DEFAULT_NODE = "primary"
node_type    = ARGV[0] || DEFAULT_NODE
node_type = node_type.dup
node_type.downcase!

unless node_type=="primary"
  # Anything other than primary is a slave and on port 500 by default
  default_port = config['START_FILE_NODE_READ_PORT']
  node_type = "slave"
end

port_number  = ARGV[1] || default_port

puts "port_number: #{port_number}"
puts "node_type: #{node_type}"

# Make server
server = Server.new
server.run(port_number, MAX_THREADS, node_type)
