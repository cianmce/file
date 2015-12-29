# ./start_primary.sh AMOUNT START_PORT

AMOUNT=${1:-2}
START_PORT=${2:-6000}


# ruby app.rb $1
for ((i=0; i<$AMOUNT; i++)); do
    PORT=$(($i + $START_PORT));
    # echo "ruby app.rb primary $PORT";
    (ruby app.rb primary $PORT;)&
done
