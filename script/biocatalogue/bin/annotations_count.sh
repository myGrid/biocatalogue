#!/usr/bin/env bash

# BioCatalogue: script/biocatalogue/annotations_count.sh
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.


# Application Base Directory
base_dir=`pwd`

# Rails Environment
environment=development

while getopts "he:" opt; do
    case $opt in
	h)
		echo "Description:"
	   	echo "Launches a job to run annotations counts in a background process"
		echo "Requirements:"
		echo "1) This script should be launched from <RAILS_ROOT>"
		echo "2) Background daemons process should be running. It is started with [ script/worker start] "
		echo ""
		echo >&2 "Usage: $0 [-h] [-e environment] "
		exit 0;;
	e) 	
		environment="$OPTARG";;

	[?])	echo >&2 "Usage: $0 [-h] [-e environment] "
		exit 1;;
	esac
done

echo $base_dir
echo "Running $0 in $environment mode"

echo "Changing directory to : $base_dir"
cd $base_dir

echo "Annotation counts"
rake biocatalogue:submit:calculate_annotation_counts RAILS_ENV=$environment

