# File Server

Each "file node" is in charge of a number of directories in the base directory that fall under their alphabet range.

![Flow](img/file_server.png)


e.g. with 2 nodes, the 1st take the any directory containing a-m and the 2nd takes n-z

Any directories starting with a number or special character will be placed in the first or last node depending where that character is in the ASCII table.

All servers communicate with each other with a single line of JSON that follows the schema

```json

{
    "method": "method_name",
    "param": "params for this action"
}

```

e.g.

```json

{
"method": "lookup",
    "param": [
        "write",
        "a_Dir/file.txt"
    ]
}

```



# Start
## Start file nodes

#### Primary Nodes

Primary nodes only receive writes from the client proxy and forward them to the appropriate slave node. 

`./file_nodes/start_primary.sh 0`

`./file_nodes/start_primary.sh 1`

#### Slave Nodes

Slave nodes receive write commands from primary nodes and read commands from the client proxy

`./file_nodes/start_slave.sh 0`

`./file_nodes/start_slave.sh 1`

## Directory Server

Slits files and directorys alphabetically based on the first character in the path.

e.g. With 2 file servers, and base file or directory beginning with [a-m] would go on file node #0, [n-z] would be on file node #1

`./directory_server/start.sh`

## Client Proxy

Interprets command sent be the client. Contacts directory, lock and file servers using JSON



`./client_proxy/start.sh`

## Lock Server

`./lock_server/start.sh`

## Sample Client

`ruby sample_client.rb`

#### Client usage

Commands:

`ls`, `pwd`, `cd`, `mkdir`, `read`/`cat`, `write`, `rm`, `exit`


**ls**

`ls [-l]` - Directory list for current directory - stored by the client proxy for each socket, flag -l lists file vertically 

e.g.
`ls` -> `zz.txt  a_folder/`

**pwd**

`pwd` - Print Working Directory - stored by the client proxy for each socket

e.g.
`pwd` -> `/a_folder`

**cd**

`cd <directory_name>` - Change Directory

e.g.
`cd a_folder` -> `/a_folder`

`cd .` -> `/a_folder`

`cd ..` -> `/`

**mkdir**

`mkdir <directory_name>` - Make a directory

e.g.

`mkdir fff` -> `created`

**read/cat**

`read <file_name>` or `cat <file_name>` - Display the contents of a file

e.g.

`read zz.txt` -> `some test`

`read a_folder/zz.txt` -> `some test`

**write**

`write <file_name> [-a] "<contents>"` - Writes contents to file. Append, -a, flag appends contents to file. \n and \t can be used to make new lines and tabs. Returns number of bytes written

e.g.

`write zz.txt -a "some stuff\nmore stuff\n\t\tIndented\n"` -> `33`

`write a_folder/zz.txt "some stuff\nmore stuff\n\t\tIndented\n"` -> `33`

**rm**

`rm [-rf] <file_name or directory>` - Deletes a folder or file and everything in the directorys

e.g.

`rm zz.txt` -> `done`

`rm a_folder"` -> `ERROR: not found` - a_folder is not a file, so it's not found

`rm -rf a_folder"` -> `done`

**exit**

`exit` - Closes socket and quits
