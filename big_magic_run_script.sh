#!/bin/bash

echo "This needs xterm to be installed"

echo "Starting 2 Primary File Nodes..."
(xterm -e ./file_nodes/start_primary.sh 0 )&
(xterm -e ./file_nodes/start_primary.sh 1 )&

echo "Starting 2 Slave File Nodes..."
(xterm -e ./file_nodes/start_slave.sh 0 )&
(xterm -e ./file_nodes/start_slave.sh 1 )&

echo "Starting Directory Server..."
(xterm -e ./directory_server/start.sh )&

echo "Starting Client Proxy..."
(xterm -e ./client_proxy/start.sh )&

echo "Starting Lock Server..."
(xterm -e ./lock_server/start.sh )&

echo "Starting Client..."
sleep 2
ruby sample_client.rb

