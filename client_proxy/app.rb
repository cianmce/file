require_relative 'client_proxy'

require 'yaml'

config = YAML.load_file(File.dirname(__FILE__)+'/../config/config.yml')

MAX_THREADS  = config['MAX_THREADS']
STUDENT_ID   = 'a04dcb0fee025f2b48663ba413d0b8d481db11b65b254d41e3611b834c17d6d5'
DEFAULT_PORT = config['CLIENT_PROXY_PORT']
port_number  = ARGV[0] || DEFAULT_PORT


# Make server
server = Server.new(STUDENT_ID)
server.run(port_number, MAX_THREADS)
