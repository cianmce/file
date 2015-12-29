
MYDIR="$(dirname "$(readlink -f "$0")")"
file_name=$MYDIR/app.rb

ruby $file_name $1
