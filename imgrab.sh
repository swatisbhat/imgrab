#!/bin/bash

usage()
{
echo -e "\n${BL}${BOLD}${UL}HELP${RESET}"
echo -e "\n\n${BL}${BOLD}USAGE:\n\n\t${WH}${BOLD}`basename $0` [OPTIONS] [url]"
echo -e "\n\t${GR}${BOLD}Downloads all images from a specified url.\n\tDefault formats downloaded : ${WH}${BOLD}png,jpg,jpeg,gif,tif,bmp\n\t${GR}${BOLD}Default download location  :${WH}${BOLD} sub-directory in current directory"
echo -e "\n\n${BL}${BOLD}OPTIONS:"
echo -e "\n\t${WH}${BOLD}-h                           ${GR}${BOLD}Print this help menu"
echo -e "\t${WH}${BOLD}-o DIR                       ${GR}${BOLD}Save all images in the directory DIR"
echo -e "\t${WH}${BOLD}-f \"ext1 ext2 ext3 ..\"       ${GR}${BOLD}Download specified formats/extensions only"
echo -e "\t${WH}${BOLD}-x \"ext1 ext2 ext3 ..\"       ${GR}${BOLD}Exclude specified formats/extensions and download the rest"
echo -e "\t${WH}${BOLD}-l NUM                       ${GR}${BOLD}Print last NUM entries of log file"
echo -e "\t${WH}${BOLD}-L                           ${GR}${BOLD}Print full log history"
echo -e "\n\n${BL}${BOLD}EXAMPLES:"
echo -e "\n\t${GR}${BOLD}Download all the images and save them in the user input directory"
echo -e "\t${WH}${BOLD}`basename $0` -o ~/my/input/dir [url]"
echo -e "\n\t${GR}${BOLD}Download only png images and save them in the user input directory"
echo -e "\t${WH}${BOLD}`basename $0` -o ~/my/input/dir -f \"png\" [url]"
echo -e "\n\t${GR}${BOLD}Download all images except png and jpg"
echo -e "\t${WH}${BOLD}`basename $0` -x \"png jpg\" [url]"
echo -e "\t${GR}${BOLD}(This will save the images in a sub-dir [url-images] in the current directory)\n${RESET}"
}

#DEFAULTS
otrue=0
ftrue=0
xtrue=0
ltrue=0
Ltrue=0
DATETIME="`date +%Y%m%d%H%M`"
j=0
total_size=0
t_count=0
folder="$HOME/.imgrab"
#Colour setttings
RED='\e[1;31m'
CYAN='\e[1;36m'
NC='\e[0m'
BL='\e[1;34m'
GR='\e[0;32m'
WH='\e[1;37m'
YEL='\e[1;33m'
DG='\e[1;30m'

BOLD=`tput bold`
UL=`tput smul`
RESET=`tput sgr0`

#----------------------------------------------------------------------------#
#spinner function to display progress working indicator
#Source: http://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-working-indicator

spinner()
{
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
i=$(( (i+1) %4))

printf "\r${spin:$i:1} ${j}/${t_count} $filename %.4fKB          " "$size"
sleep .1
done
echo -ne "\r\b>Finishing up...                        "
}
#----------------------------------------------------------------------------#
#trap Cltr-C

control_c()
# run if user hits control-c
{
echo -en "\nDownload interrupted by user.\n"
echo -ne "`date '+%Y/%m/%d %H:%M:%S'` ${short_url} ${t_count} ${j} Interrupted\n">>$folder/log
exit
}
 
# trap keyboard interrupt (control-c)
trap control_c SIGINT

#----------------------------------------------------------------------------#
#print_log function to print log history
print_log()
{
if [ $ltrue == 1 ]                       
#print last n entries of log file    
then
awk 'BEGIN{printf("--------------------------------------------------------------------------------------\n%-11s %-9s %-30s %-6s %-11s %-13s\n","DATE","TIME","URL","FOUND","DOWNLOADED","STATUS")} {printf("%-11s %-9s %-30s %-6s %-11s %-13s\n",$1,$2,$3,$4,$5,$6)}' $folder/log|awk -v NUM="$n_entries" '{a[i++]=$0} END {printf("%s\n%s\n%s\n",a[0],a[1],a[0]);for(j=i-1;j>=i-NUM;j--) print a[j];print a[0]}'
else
if [ $Ltrue == 1 ]                       
#print full log history
then
awk 'BEGIN{printf("--------------------------------------------------------------------------------------\n%-11s %-9s %-30s %-6s %-11s %-13s\n","DATE","TIME","URL","FOUND","DOWNLOADED","STATUS")} {printf("%-11s %-9s %-30s %-6s %-11s %-13s\n",$1,$2,$3,$4,$5,$6)}' $folder/log|awk '{a[i++]=$0} END {printf("%s\n%s\n%s\n",a[0],a[1],a[0]);for(j=i-1;j>=3;j--) print a[j];print a[0]}'
fi
fi
}

#----------------------------------------------------------------------------#
#network_error handling

error_exit()
{
echo -ne "`date '+%Y/%m/%d %H:%M:%S'` ${short_url} ${t_count} ${j} Network_Error\n">>$folder/log
echo -ne "Network Error. Make sure you're connected to the internet.\n" 1>&2
exit 1
}

#---------------------------------------------------------------------------#
# parse options
while getopts 'o:hf:x:Ll:' opt ; do
  case $opt in
    h) usage;
       exit
    ;;
    o) INPUT_DIR=$OPTARG;
	otrue=1 ;;
    f) fforms=$OPTARG;
	ftrue=1 ;;
    x) xforms=$OPTARG;
	xtrue=1;;
    l) n_entries=$OPTARG;
        ltrue=1 ;
        print_log;
        exit;;
    L) Ltrue=1;
        print_log;
        exit;;
    \?) 
        echo -e "Type${GR}${BOLD} `basename $0` -h ${RESET}to display help";
        exit
        ;;
    :) echo "Option -$OPTARG requires an argument">&2;
       echo -e "Type${GR}${BOLD}`basename $0` -h ${RESET}to display help";
       exit
       ;;

  esac
done

#skip the processed options
shift $((OPTIND-1))

#make sure one and only one mandatory arg(url) is present
if [ $# -ne 1 ]
then
echo "Invalid syntax, argument missing."
echo -e "Type${GR}${BOLD}`basename $0` -h${RESET} to display help"
exit
fi

URL=$1

if [ "${URL:0:7}" != 'http://' -a "${URL:0:8}" != 'https://' ]
then
URL='http://'$URL
fi
printf "Connecting to: ${URL}\n"

short_url="`echo "$URL"|grep -Po '(http|https)://.+?(/|$)'`"

#Send GET request and obtain html
IFS=/ read protocol blank host query <<<"$URL";
exec 3< /dev/tcp/$host/80||error_exit;
{
echo GET /$query HTTP/1.1;
echo connection: close;
echo host: $host;
echo
}>&3;

#Remove headers and extract image links
file=( `sed '1,/^$/d' 0<&3|grep -oP 'src="\K\S+?(jpg|png|jpeg|gif|bmp|tif)(?=")'|sort -u|tee args`)

t_count=${#file[@]}
tot_count=$t_count;
echo "Total Images Found : ${t_count}"

#Customize as per options supplied
if [ $ftrue -eq 1 ]
then
echo -e "Applying filter..."
ext="$fforms"
for t in ${ext[@]}
do
sed -n '/.*'"$t"'/p' args>>temp
done
mv temp args
fi

if [ $xtrue -eq 1 ]
then
echo -e "Excluding specified formats..."
ext="$xforms"
for t in ${ext[@]}
do
sed -n '/.*'"$t"'/!p' args>>temp
done
mv temp args
fi

file=(`cat args`)
t_count=$(wc -w<args)
rm args

echo "Downloading ${t_count} Images"

#set default directory if not specified
if [ $otrue -eq 0 ]
then
INPUT_DIR="`pwd`/${host}-images"
fi

#Check if directory exists, creat one if it doesn't
if [ ! -d "$INPUT_DIR" ]
then
mkdir $INPUT_DIR
fi
path="$INPUT_DIR"



#Read each link

for t in "${file[@]}"
do
#PRE-PROCESSING
#Set custom filename with extension
j=$((j+1));
extnsn=$(echo $(basename $t) | sed "s/.*\(\.[^\.]*\)$/\1/");
filename="${DATETIME}_IMG0${j}${extnsn}";

link=$t

#check for relative links and convert them to absolute links
if [ "${link:0:4}" != "http" ]
then
export URL link
export abs_link=`python -c 'import os; base=os.environ["URL"]; rel=os.environ["link"]; from urlparse import urljoin; print urljoin(str(base).strip(),str(rel).strip())'`
else
abs_link=$link
fi

printf "\rFetching file info...                            "

#Parse headers
IFS=/ read protocol blank host query <<<"$abs_link";

exec 3< /dev/tcp/$host/80||error_exit;
{
echo HEAD /$query HTTP/1.1;
echo connection: close;
echo host: $host;
echo
}>&3;

#get file size
size=$(sed 's/.*/&/' 0<&3|grep Content-Length|awk '{print $2}'|tr -d '\r');
size=$(echo "$size/1024"|bc -l)
total_size=$(echo "$total_size + $size"|bc -l);

#download image with curl and save in custom location
(curl -s $abs_link > "${path}/${filename}") & spinner;
done

if [ $j -eq $t_count ]
then
printf "\rFinished Downloading $t_count Images (%.2fKB)\n" "$total_size"
echo -ne "`date +"%Y/%m/%d %H:%M:%S"` $short_url $t_count $j Successful\n">>$folder/log
fi
