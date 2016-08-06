# imgrab
A light-weight image download manager written in bash
##INSTALLATION
    unzip imgrab-master.zip
    cd imgrab-master
    sh configure
Move the ~/bin/imgrab file to any folder you wish that is callable through ~/.profile

##USAGE:
    imgrab [OPTIONS] [url]

	Downloads all images from a specified url.
	Default formats downloaded :   png,jpg,jpeg,gif,tif,bmp
	Default download location  :   sub-directory in current directory

##OPTIONS:
    -h                             Print help menu
  	-o DIR                         Save all images in the directory DIR
  	-f "ext1 ext2 ext3 .."         Download specified formats/extensions only
  	-x "ext1 ext2 ext3 .."         Exclude specified formats/extensions and download the rest
  	-l NUM                         Print last NUM entries of log file
  	-L                             Print full log history
  	
##EXAMPLES:
    Download all the images and save them in the user input directory
    imgrab -o ~/my/input/dir [url]

    Download only png images and save them in the user input directory
    imgrab -o ~/my/input/dir -f "png" [url]

    Download all images except png and jpg
    imgrab -x "png jpg" [url]
	  (This will save the images in a sub-dir [url-images] in the current directory)
 

