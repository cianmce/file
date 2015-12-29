require_relative 'lock_server'


MAX_THREADS  = 5
STUDENT_ID   = 'a04dcb0fee025f2b48663ba413d0b8d481db11b65b254d41e3611b834c17d6d5'
DEFAULT_PORT = 5002
port_number  = ARGV[0] || DEFAULT_PORT


# Make server
server = Server.new(STUDENT_ID)
server.run(port_number, MAX_THREADS)
