require_relative 'file_server'


MAX_THREADS  = 5
DEFAULT_PORT = 6000
DEFAULT_NODE = "primary"
node_type    = ARGV[0] || DEFAULT_NODE
node_type = node_type.dup
node_type.downcase!

unless node_type=="primary"
  # Anything other than primary is a slave and on port 500 by default
  DEFAULT_PORT = 7000
  node_type = "slave"
end

port_number  = ARGV[1] || DEFAULT_PORT

puts "port_number: #{port_number}"
puts "node_type: #{node_type}"

# Make server
server = Server.new
server.run(port_number, MAX_THREADS, node_type)
