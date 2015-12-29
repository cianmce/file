require 'socket'
require 'json'

require 'yaml'
config = YAML.load_file('config/config.yml')


DEFAULT_PORT = config['CLIENT_PROXY_PORT']
port_number  = ARGV[0] || DEFAULT_PORT
hostname = "localhost"

s = TCPSocket.open(hostname, port_number)

def make_request(s, text)
  s.puts "#{text}\r\n"
  data = s.gets
  JSON.parse(data)
end

def get_input
  print "> "
  input = gets.chomp
end

while true
  input = get_input
  if input != ''
    response = make_request(s, input)
    if response['status']>299
      puts "ERROR:"
    end
    puts response['response']

    if input.downcase.start_with?"exit"
      break
    end
  end
end

s.close
puts "Bye :)\n"
