#!/bin/sh

# Check Pod
podchecker  GUITest.pm GUITest.xs
if [ $? -ne 0 ] 
then
	echo 'POD validation failed!  Documentation will not be processed.'
	exit 1
else
	echo 'POD validation passed.  Documentation being processed.'
fi

# Make Documents
echo 'Processing POD...'
cat GUITest.pm >PODTemp
cat GUITest.xs >>PODTemp
pod2text PODTemp docs/X11-GUITest.txt
pod2html --infile=PODTemp --outfile=docs/X11-GUITest.html
echo 'Finished processing POD.'

# Clean Up
echo 'Removing residual files...'
rm -f pod*.x?? PODTemp

echo 'Complete'
