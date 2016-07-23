#!/bin/bash

usage() 
{
echo "Usage: $0 [optional arguments] [url]"
echo "Command line options:"
echo "    -o  DIR     Save all pictures in DIR directory(by default all pictures are saved in the current directory)"
echo "    -h          Print this help menu"
echo "Example: Download all the pictures and save them in the user input directory"
echo "    $0 -o ~/my/input/dir [url]"
}



#echo "$COMMAND_LINE_OPTIONS_HELP"
INPUT_DIR="`pwd`"
# parse the options
while getopts 'o:h' opt ; do
  case $opt in
    h) echo "$COMMAND_LINE_OPTIONS_HELP"
       exit 
    ;;
    o) INPUT_DIR=$OPTARG ;;
    \?)
            echo "Usage: $0 -h for help";
            usage;
            exit
        ;;
    :) echo "Option -$OPTARG requires an argument";
       usage;
       exit 
       ;;

  esac
done

shift $((OPTIND-1))

URL=$1

spinner()
{
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
i=$(( (i+1) %4))
#printf "\r$(basename $t) ${spin:$i:1}"

printf "\r${spin:$i:1} ${j}/${t_count} $filename %.4fKB          " "$size"
sleep .1
done
echo -ne "\r\b>Finishing up..........."

}

#main function
#########----DECLARATIONS------#######
j=0
total_size=0


#########-----------------------######


if [ "${URL:0:7}" != 'http://' ]
then
URL='http://'$URL
fi
printf "Connecting to: ${URL}"
IFS=/ read protocol blank host query <<<"$URL";

exec 3< /dev/tcp/$host/80;
{
echo GET /$query HTTP/1.1;
echo connection: close;
echo host: $host;
echo
}>&3;

#file=( `sed '1,/^$/d' 0<&3|grep -oP '<img.*?>'|grep -oP 'src="\K\S+(jpg|png|jpeg)(?=")'` )

file=( `sed '1,/^$/d' 0<&3|grep -oP 'src="\K\S+?(jpg|png|jpeg)(?=")'|sort -u`)
#file=( `sed '1,/^$/d' 0<&3|egrep -o 'http://\S+(jpg|jpeg|png)'` )
#file=(`cat arg2.txt`)
#t_count=$(wc -w<arg2.txt)

t_count=${#file[@]}
#setting download location
#if [ -z "$2" ]
#then 
#current_dir="`pwd`"
#path=$current_dir
#else
if [ ! -d "$INPUT_DIR" ]
then 
mkdir $INPUT_DIR
fi
path="$INPUT_DIR"
#fi




for t in "${file[@]}"
do 
j=$((j+1));
ext=$(echo $(basename $t) | sed "s/.*\(\.[^\.]*\)$/\1/");
filename="${j}${ext}";
#size=$(curl -sI $t|grep Content-Length|awk '{print $2}'|tr -d '\r');

link=$t
if [ "${link:0:4}" != "http" ]
then 
export URL link
export abs_link=`python -c 'import os; base=os.environ["URL"]; rel=os.environ["link"]; from urlparse import urljoin; print urljoin(str(base).strip(),str(rel).strip())'`
else
abs_link=$link
fi
printf "\rFetching file info"

IFS=/ read protocol blank host query <<<"$abs_link";

exec 3< /dev/tcp/$host/80;
{
echo HEAD /$query HTTP/1.1;
echo connection: close;
echo host: $host;
echo
}>&3;

size=$(sed 's/.*/&/' 0<&3|grep Content-Length|awk '{print $2}'|tr -d '\r');
#total_size=$(( total_size + $size));	
size=$(echo "$size/1024"|bc -l)
(curl -s $abs_link > "${path}/${filename}") & spinner;
done
















