#!/bin/bash

root_dir=
software_dir=
mkdir -p $software_dir

# === Installing Sockeye
# Note: Sockeye requires python3
sockeye_path=$software_dir/sockeye
if [ ! -d $sockeye_path ]; then
	cd $software_dir
        git clone https://github.com/awslabs/sockeye.git	
	cd $sockeye_path
	pip install . --no-deps -r requirements/requirements.gpu-cu101.txt
fi;

# === Installing Moses scripts 
moses_scripts_path=$software_dir/moses-scripts
if [ ! -d $moses_scripts_path ]; then
	cd $software_dir
	git clone https://github.com/moses-smt/mosesdecoder.git
	cd mosesdecoder
	git checkout 06f519d
	cd $software_dir
	mv mosesdecoder/scripts moses-scripts
	rm -rf mosesdecoder
fi;

