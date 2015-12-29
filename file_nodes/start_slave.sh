# ./start_slave.sh AMOUNT START_PORT

AMOUNT=${1:-2} # default 2
START_PORT=${2:-7000}


# ruby app.rb $1
for ((i=0; i<$AMOUNT; i++)); do
    PORT=$(($i + $START_PORT));
    echo "ruby app.rb slave $PORT"; 
done
