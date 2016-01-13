#!/bin/bash

# paths
export PATH=/usr/local/Cellar/erlang/R16B02/bin:$PATH

# misc
log_sep="---------------------------------------------"

# Messages
error_cc="Unable to get Code change information"
error_parse="Unable to Parse"
error_na="NA"

# files
riakbin="$WORKSPACE/riak_test/riak_test"
test_cases="$WORKSPACE/antidote/riak_test/*.erl"
antidote_bin="$HOME/rt/antidote/current/dev/dev*/bin/antidote"
riak_configf="$HOME/.riak_test.config"
antidote_current="$WORKSPACE/antidote/riak_test/bin/antidote-current.sh"
antidote_setup="$WORKSPACE/antidote/riak_test/bin/antidote-setup.sh"
code_histroy="$HOME/.code_histroy"

# Vars
is_timeout=0
is_perl=0
is_awk=0
is_sed=0
is_erl=0
is_erlc=0
is_git=0
is_grep=0
riak_changed=0
antidote_changed=0
test_pass_cnt=0
test_failed_cnt=0
test_cnt=0
declare -a failed_fns
declare -a failed_errors

# Time out
max_time=3600 #in seconds

# requirment test -1
if type "timeout" > /dev/null 2>&1 ; then
	is_timeout=1
fi
if type "perl" > /dev/null 2>&1 ; then
    is_perl=1
fi
if type "awk" > /dev/null 2>&1 ; then
    is_sed=1
fi
if type "sed" > /dev/null 2>&1 ; then
    is_sed=1
fi
if type "erl" > /dev/null 2>&1 ; then
	is_erl=1
fi
if type "erlc" > /dev/null 2>&1 ; then
	is_erlc=1
fi
if type "git" > /dev/null 2>&1 ; then
	is_git=1
fi
if type "grep" > /dev/null 2>&1 ; then
	is_grep=1
fi


# min req.
if [ -z $WORKSPACE ] || [ -z $HOME ] || [ "$is_sed" -eq 0 ] \
	|| [ "$is_erl" -eq 0 ] || [ "$is_erlc" -eq 0 ] \
    || [ "$is_grep" -eq 0 ] #do we need sed ?
then
	echo "Required support (minimum) not found, exiting ..."
    exit 1
fi
if [ -d $WORKSPACE ] && [ -d $HOME ] \
    && [ -d $WORKSPACE/riak_test ] \
    && [ -d $WORKSPACE/antidote ]
then
	echo ""
	echo $log_sep
else
	echo "Required support (Paths) not found, exiting ..."
    exit 1
fi

# select time out
if [ "$is_timeout" -eq 1 ]; then
	echo "Using bash timeout function ..."
	function alarm() { timeout "$@"; }
elif [ "$is_perl" -eq 1 ] ; then
	echo "Using perl script for timeout function ..."
	function alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }
else
	echo "Time out support not found ..."
    echo "WARNING : The test will run as log the Jenkins KILLs it ..."
    function alarm() { bash "${@:2}"; }
fi

# timer
function timer()
{
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        printf '%d' $dt
    fi
}

# clean old dev's
function clean_dev()
{
	echo "Clearing all old dev's ...." 
	for dev_bin in $(ls -1 $antidote_bin); do
		is_antinode_up=$($dev_bin ping 2>/dev/null \
        | grep "pong" | wc -l | sed 's/^ *//g')
    	if [ "$is_antinode_up" -eq 1  ]
    	then
    		echo "$dev_bin -"
            echo "is up, stoping it ..."
    		$dev_bin stop
    	fi
	done
}

# riak config file
if [ -f $riak_configf ]
then
	echo "The riak test config file found"
    #cat $riak_configf
    #echo ""
else
	echo "The riak test config file not found, creating it .."
cat > $riak_configf << EOL
{default, [
    {platform, "osx-64"},
    {rt_max_wait_time, 600000},
    {rt_retry_delay, 1000},
    {rt_harness, rtdev},
    {rt_scratch_dir, "/tmp/riak_test_scratch"},
    {basho_bench, "/Users/cmeiklejohn/Basho/basho_bench"},
    {load_workers, 10},
    {lager_level, info}
]}.
{antidote, [
    {rt_project, "antidote"},
    {cluster_a_size, 3},
    {num_nodes, 6},
    {exec_name, "antidote"},
    {rt_cookie, antidote},
    {test_paths, ["$WORKSPACE/antidote/riak_test/ebin"]},
    {rtdev_path, [{root, "$HOME/rt/antidote"},
                  {current, "$HOME/rt/antidote/current"}]}
]}.

{intercept_example,
 [
  {load_intercepts, true},
  {intercepts,
   [
    {riak_kv_vnode, [{{put,7}, dropped_put}]}
   ]}
 ]}.
EOL
fi

# dir chmod
chmod -R 755 $WORKSPACE/riak_test
chmod -R 755 $WORKSPACE/antidote

# clean old files
if [ -d $WORKSPACE/utest ]; then
	echo "Clearing old test result temp files ..."
    rm -rf $WORKSPACE/utest/*.xml
else
	echo "Creating test result temp dir ..."
	mkdir $WORKSPACE/utest
fi

if [ -d $WORKSPACE/tlog ]; then
	echo "Clearing old temp logs ..."
    rm -rf $WORKSPACE/tlog/*.log
else
	echo "Creating temp logs dir ..."
	mkdir $WORKSPACE/tlog
fi

# setup antinode
cd $WORKSPACE/antidote/ # Nevr remove this the script need 
			  			# to run inside antidote dir
if [ -d $HOME/rt ]; then
	echo "Updating with antidote current ..."
    if [ -f $antidote_current ]
    then
    	$antidote_current
    else
    	echo "Unable to read $antidote_current .."
        exit 1
    fi
else
	echo "Creating antidote setup ..."
    if [ -f $antidote_setup ]
    then
    	mkdir $HOME/rt
    	$antidote_setup
    else
    	echo "Unable to read $antidote_setup .."
        exit 1
    fi
fi

# create link to rt
if [ -d $WORKSPACE/rt_link ]
then
	echo "rt link is present ..."
else
	echo "Linking rt for web access ..."
	rm $WORKSPACE/rt_link 2> /dev/null
	ln -s $HOME/rt $WORKSPACE/rt_link
fi

# dir chmod
chmod -R 755 $HOME/rt

# requirment test -2
is_antidote_bin=$(ls -1 $antidote_bin 2>/dev/null \
	| wc -l | sed 's/^ *//g')
if [ -f "$riakbin" ] && [ "$is_antidote_bin" -ge 6 ] \
	&& [ -f "$riak_configf" ]
then
    echo "Found antidote bin and riak config in place ..."
else
	echo "Required support (antidote bin and riak config) not found, exiting ..."
    exit 1
fi

# Get branch info
#
riak_HEAD_old="$error_na"
riak_HEAD=$(cat $WORKSPACE/riak_test/.git/HEAD)
riak_name=$(cat $WORKSPACE/riak_test/.git/FETCH_HEAD | grep -w "$riak_HEAD" | cut -d"'" -f2)
echo "Using riak_test branch : $riak_name"
if [ -d $code_histroy/riak_test/$riak_name ]
then
	if [ -f $code_histroy/riak_test/$riak_name/sHEAD ]
	then
    	echo "Found a sucessfull test with this riak branch ..."
  		riak_HEAD_old=$(cat $code_histroy/riak_test/$riak_name/sHEAD 2>/dev/null)
    else
    	echo "Not Found a sucessfull test with this riak branch ..."
	fi
else
	echo "Running first time with this branch ..."
	mkdir -p $code_histroy/riak_test/$riak_name
fi

#
antidote_HEAD_old="$error_na"
antidote_HEAD=$(cat $WORKSPACE/antidote/.git/HEAD)
antidote_name=$(cat $WORKSPACE/antidote/.git/FETCH_HEAD | grep -w "$antidote_HEAD" | cut -d"'" -f2)
echo "Using antidote branch : $antidote_name"
if [ -d $code_histroy/antidote/$antidote_name ]
then
	if [ -f $code_histroy/antidote/$antidote_name/sHEAD ]
	then
    	echo "Found a sucessfull test with this antidote branch ..."
   		antidote_HEAD_old=$(cat $code_histroy/antidote/$antidote_name/sHEAD 2>/dev/null)
    else
    	echo "Not Found a sucessfull test with this antidote branch ..."
	fi
else
	echo "Running first time with this branch ..."
	mkdir -p $code_histroy/antidote/$antidote_name
fi

# clean old dev's
clean_dev

# test loop
for file_test in $(grep -l confirm/0 $test_cases 2>/dev/null)
do
    fn_test=$(basename $file_test .erl)
     
	# local vars
    t=0
    test_fail=0
    test_pass=0
    
    # default messages
    fail_message="$fn_test Failed"
    fail_type="Unknown"
    error_message="Error in $fn_test"
    error_type="Unknown"
    
    # local files
    test_logf="$WORKSPACE/tlog/$fn_test.log"
    utest_file="$WORKSPACE/utest/Test-"$fn_test".xml"

	test_cnt=$((test_cnt+1))

	# Test exec
    echo ""
    echo $log_sep
    echo "$test_cnt) Test : $fn_test"
    echo ""
    
    echo "$riakbin -v -c antidote -t $fn_test"
    t=$(timer)
    
    # Keep this as single line
	alarm $max_time $riakbin -v -c antidote -t $fn_test 2>&1 | tee -a $test_logf
       
    time_sec=$(timer $t)
    echo ""
    echo $log_sep
    
    # Test result processing
    echo "Time taken for $fn_test (seconds) :$time_sec"
     
    if [ -f $test_logf ]
    then
    	echo "Processing Test result ..."
    	test_pass=$(cat $test_logf 2>/dev/null \
        	| grep "$fn_test-error: pass" | wc -l | sed 's/^ *//g')
     	test_fail=$(cat $test_logf 2>/dev/null \
        	| grep "$fn_test-error: fail" | wc -l | sed 's/^ *//g')
    else
     	echo "Error : The test log not found .."
    fi
    
    if [ "$test_pass" -eq 0 ] 
    then
    	echo ""
    	echo $log_sep
		clean_dev
    	echo $log_sep
        echo ""
    fi
    
    # default 
    error_info="NA"
    fail_info="NA"
    
	if [ -f $test_logf ] && [ "$test_pass" -eq 1 ] && [ "$test_fail" -eq 0 ]
    then
        echo "The test is detected as passed[$test_pass]"
        test_pass_cnt=$((test_pass_cnt+1))
    elif [ -f $test_logf ] && [ "$test_pass" -eq 0 ] && [ "$test_fail" -eq 1 ]
    then
    	echo "The test is detected as failed[$test_pass]"
        failed_fns[test_failed_cnt]="$fn_test "       
        if [ "$time_sec" -ge "$max_time" ]
        then
            error_message="$fn_test is stopped forcefully, \
as it exceeded maximum run time($max_time sec)"
            error_type="stopped"
            fail_message="$fn_test is stopped forcefully, \
as it exceeded maximum run time($max_time sec)"
            fail_type="stopped"
            failed_errors[test_failed_cnt]="$fail_message"
        else
        	echo "Collecting Error info ..."
        	if [ "$is_perl" -eq 1 ]; then
        		failed_errors[test_failed_cnt]=$(cat $test_logf \
            		2>/dev/null | perl -ne \
            		'print "$1\n" if /(?<=$fn_test-error: fail <<")(.+?)(?=">>)/' \
                    | perl -pe 's/>/ /g' | perl -pe 's/</ /g')
            elif [ "$is_awk" -eq 1 ]; then
            	failed_errors[test_failed_cnt]=$(cat $test_logf \
            		2>/dev/null | awk -v \
                    FS="($fn_test-error: fail <<\"|\">>)" '{print $2}')
            elif [ "$is_sed" -eq 1 ]; then
        		failed_errors[test_failed_cnt]=$(cat $test_logf \
            		2>/dev/null | sed -n \
            		'/$fn_test-error: fail <<\"/,/\">>/' \
                    | sed 's/<//g' | sed 's/>//g')
            else
            	echo "No support to collecting Error info ..."
            	failed_errors[test_failed_cnt]="$error_parse"
            fi
            error_type="exicution-error"
            error_message="$fn_test is failed, \
as it has exicution-error(check the logs : $BUILD_URL)"
            fail_message="$fn_test is failed, \
as it has exicution-error(check the logs : $BUILD_URL)"
            fail_type="exicution-error"
            # Setting Error info
            e_temp="0"
        	e_temp="${failed_errors[$test_failed_cnt]}"
        	#there is somthing in first few characters
        	is_anerror=$(echo ${e_temp:2:6})
        	if [ -z $is_anerror ] \
               || [ "${failed_errors[$test_failed_cnt]}" == "$error_parse" ]
        	then
            	echo "Error Info - $error_parse .."		
        	else
            	error_info=$(echo -e "${failed_errors[$test_failed_cnt]}")
            	fail_info=$(echo -e "${failed_errors[$test_failed_cnt]}")
        	fi
        fi
        test_failed_cnt=$((test_failed_cnt+1))
	else
    	failed_fns[test_failed_cnt]="$fn_test "
        if [ -f $test_logf ] && [ "$time_sec" -ge "$max_time" ]
        then
        	echo "The test is stoped, marking as failed[$test_pass]"
            error_message="$fn_test is stopped forcefully, \
as it exceeded maximum run time($max_time sec)"
            error_type="stopped"
            fail_message="$fn_test is stopped forcefully, \
as it exceeded maximum run time($max_time sec)"
            fail_type="stopped"
        elif [ -f $test_logf ]
        then
         	echo "Something was wrong with $fn_test after started .."
            echo "The test is marked as failed[$test_pass]"
            fail_message="$fn_test Failed, Unknown"
     		fail_type="Unknown"
     		error_message="Error in $fn_test, Unknown"
     		error_type="Unknown"
        else
         	echo "Something was wrong with $fn_test, \
it dosen't look like started .."
            echo "The test is marked as failed[$test_pass]"
            error_message="$fn_test not executed, \
something was wrong with $fn_test"
            error_type="not-executed"
            fail_message="$fn_test not executed, \
something was wrong with $fn_test"
            fail_type="not-executed"
        fi
        failed_errors[test_failed_cnt]="$fail_message"
        test_failed_cnt=$((test_failed_cnt+1))
	fi
    
    # use branch as test sute name to keep track of fail in diffrent barch
    if [ -z $antidote_name ]
    then
    	echo "Unable to get branch name ..."
    	group_name=$fn_test
    else
    	group_name=$antidote_name
    fi
    
    touch $utest_file
    
    if [ -f $test_logf ] && [ "$test_pass" -eq 1 ]
    then

cat > $utest_file << EOL
<?xml version="1.0" encoding="UTF-8" ?>
<testsuite tests="1" failures="0" errors="0" skipped="0" time="$time_sec" name="$group_name">
  <testcase time="$time_sec" name="$fn_test"/>
</testsuite>
EOL

	else  

cat > $utest_file << EOL
<?xml version="1.0" encoding="UTF-8" ?>
<testsuite tests="1" failures="1" errors="1" skipped="0" time="$time_sec" name="$group_name">
  <testcase time="$time_sec" name="$fn_test">
    <error message="$error_message" type="$error_type"> $error_info </error>
    <failure message="$fail_message" type="$fail_type"> $fail_info </failure>
  </testcase>
</testsuite>
EOL

	fi 

    if [ -f  $utest_file ]
    then
    	echo "Test result file (xml) created ..."
    	#cat $utest_file
    else
    	echo "Error in test result file (xml) creation ..."
    fi

done

# Collecting Code Change information
#
echo ""
echo $log_sep
echo "Code change info ..."
riak_log="$WORKSPACE/tlog/riak_git_change.log"
if [ "$riak_HEAD" != "$riak_HEAD_old" ] 
then
	if [ "$is_git" -eq 1 ] ; then
    	echo "Found code diffrance (b:$riak_name) for riak from last successful test ..."
    	cd $WORKSPACE/riak_test
        if [ "$error_na" != "$riak_HEAD_old" ]
        then
        	echo "Generating code diff info from last successful test ..."
        	echo "Change Log          :" > $riak_log
            git log --stat "$riak_HEAD_old".."$riak_HEAD" >> $riak_log
        else
        	echo "No previous successful head info found, generating diff for last 5 changes ..."
        	echo "Change Log (last 5) :" > $riak_log
   			git log -n5 >> $riak_log
        fi
    else
    	echo "Unable to get the code diffrance (b:$riak_name) for riak ..."
    	echo "Change Log          :" > $riak_log
    	echo "$error_cc" >> $riak_log
    fi
   	riak_changed=1
    if [ "$test_pass_cnt" -eq "$test_cnt" ]
	then
		echo "Updating the successful head (b:$riak_name) info for riak ..."
      	cp $WORKSPACE/riak_test/.git/HEAD $code_histroy/riak_test/$riak_name/sHEAD
	fi
else
	echo "No code diffrance (b:$riak_name) for riak from last successful test ..."
   	riak_changed=0
fi    

#
antidote_log="$WORKSPACE/tlog/riak_git_change.log" 
if [ "$antidote_HEAD" != "$antidote_HEAD_old" ]
then
    if [ "$is_git" -eq 1 ] ; then
    	echo "Found code diffrance (b:$antidote_name) for antidote from last successful test ..."
    	cd $WORKSPACE/antidote
        if [ "$error_na" != "$antidote_HEAD_old" ]
        then
        	echo "Generating code diff info from last successful test ..."
        	echo "Change Log          :" > $antidote_log
        	git log --stat "$antidote_HEAD_old".."$antidote_HEAD" >> $antidote_log
        else
        	echo "No previous successful head info found, generating diff for last 5 changes ..."
        	echo "Change Log (last 5) :" > $antidote_log
        	git log -n5 >> $antidote_log
        fi
    else
    	echo "Unable to get the code diffrance (b:$antidote_name) for antidote ..."
    	echo "Change Log          :" > $antidote_log
    	echo "$error_cc" >> $antidote_log
    fi
   	antidote_changed=1
    if [ "$test_pass_cnt" -eq "$test_cnt" ]
	then
		echo "Updating the successful head (b:$antidote_name) info for antidote ..."
		cp $WORKSPACE/antidote/.git/HEAD $code_histroy/antidote/$antidote_name/sHEAD
	fi
else
	echo "No code diffrance (b:$antidote_name) for antidote from last successful test ..."
	antidote_changed=0
fi

# Summary
echo ""
echo $log_sep
echo "# riak_test" 
echo "branch              : $riak_name"	
if [ "$riak_changed" -eq 1 ]
then
    if [ "$riak_changed" -gt 0 ]
    then
    	echo $log_sep
    	cat $riak_log
    	echo ""
    else
    	echo ""
    fi
else
	echo "Change Log          : No change found"
    echo ""
fi

echo $log_sep
echo "# antidote"
echo "branch              : $antidote_name"
if [ "$antidote_changed" -eq 1 ]
then
    if [ "$antidote_changed" -gt 0 ]
    then
    	echo $log_sep
    	cat $antidote_log
    	echo ""
    else
    	echo ""
    fi
else
	echo "Change Log          : No change found"
    echo ""
fi

echo $log_sep
echo "Total no of tests   :$test_cnt"
echo "No of tests passed  :$test_pass_cnt"
if [ "$test_pass_cnt" -ne "$test_cnt" ]
then
	echo "No of tests failed  :$test_failed_cnt"
    loop_cnt=0
    echo ""
    echo "Failed tests summary -"
    echo $log_sep
    for failed_fn_name in "${failed_fns[@]}"
    do
    	error_temp="0"
    	echo "# $failed_fn_name"
        error_temp="${failed_errors[$loop_cnt]}"
        #there is somthing in first few characters
        is_error=$(echo ${error_temp:2:6})
        if [ -z $is_error ]
        then
        	echo "Unable to parse error info, refer the build log ($BUILD_URL)"
        else
			echo -e "Error : ${failed_errors[$loop_cnt]}"
        fi
        echo ""        
        loop_cnt=$((loop_cnt+1))
    done
    echo "Marking as FAILED"
    echo $log_sep
    echo ""
    exit 1
else
	echo "Marking as PASSED"
    echo $log_sep
    echo ""
fi

