# ./start_slave.sh ID START_PORT
# ./start_slave.sh 0
# ./start_slave.sh 1

NODE_ID=${1:-0}
START_PORT=${2:-7000}

MYDIR="$(dirname "$(readlink -f "$0")")"
file_name=$MYDIR/app.rb

PORT=$(($NODE_ID + $START_PORT));
ruby $file_name slave $PORT;
