#!/bin/bash
ft_passed="PASSED"
exportPopertyFile="$WORKSPACE/envpro/general.properties"
exportBuildFile="$WORKSPACE/envpro/ft_build.properties"


if [ "$ft_BUILD_NUMBER" -ne "$BUILD_NUMBER" ]
then
	echo "Unable to read build status from env ..."
    if [ -f $exportBuildFile ]
    then
    	echo "exporting it from property file ..."
		. $exportBuildFile
    else
    	echo "Unable to read propery file ..."
        exit 1
    fi
fi

if [ "$ft_BUILD_RESULT" != "$ft_passed" ]
then
	echo $build_exit_code
	exit 1
else
	echo $build_exit_code
fi


