# ./start_primary.sh ID START_PORT
# ./start_primary.sh 0
# ./start_primary.sh 1

NODE_ID=${1:-0}
START_PORT=${2:-6000}

MYDIR="$(dirname "$(readlink -f "$0")")"
file_name=$MYDIR/app.rb

PORT=$(($NODE_ID + $START_PORT));
ruby $file_name primary $PORT;
