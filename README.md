# File Server

Each "file node" is in charge of a number of directories in the base directory that fall under their alphabet range.

e.g. with 2 nodes, the 1st take the any directory containing a-m and the 2nd takes n-z

Any directories starting with a number or special character will be placed in the first or last node depending where that character is in the ASCII table
