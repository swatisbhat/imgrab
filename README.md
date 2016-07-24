# imgrab
A light-weight image download manager written in bash

##USAGE:
    ./imgrab.sh [OPTIONS] [url]

	Downloads all images from a specified url.
	Default formats downloaded :   png,jpg,jpeg,gif,tif,bmp
	Default download location  :   sub-directory in current directory

##OPTIONS:
    -h                             Print help menu
  	-o DIR                         Save all images in the directory DIR
  	-f "ext1 ext2 ext3 .."         Download specified formats/extensions only
  	-x "ext1 ext2 ext3 .."         Exclude specified formats/extensions and download the rest
  
##EXAMPLES:
    Download all the images and save them in the user input directory
    main.sh -o ~/my/input/dir [url]

    Download only png images and save them in the user input directory
    main.sh -o ~/my/input/dir -f "png" [url]

    Download all images except png and jpg
    main.sh -x "png jpg" [url]
	  (This will save the images in a sub-dir [url-images] in the current directory)
 

