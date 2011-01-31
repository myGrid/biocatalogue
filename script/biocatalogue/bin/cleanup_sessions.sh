#!/usr/bin/env bash

# BioCatalogue: script/biocatalogue/cleanup_sessions.sh                                                                                                                                                                          
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
	   	echo "Clear sessions older than 3 days "
		echo "Requirements:"
		echo "1) This script should be launched from <RAILS_ROOT>"
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

echo "now clear sessions older than 3 days with ...  rake biocatalogue:remove_expired_sessions  RAILS_ENV=production"
rake biocatalogue:remove_expired_sessions RAILS_ENV=$environment


