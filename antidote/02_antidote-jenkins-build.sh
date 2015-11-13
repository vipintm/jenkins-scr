#!/bin/bash

# paths
export PATH=/usr/local/Cellar/erlang/R16B02/bin:$PATH

# misc
log_sep="---------------------------------------------"

# Messages
error_cc="Unable to get Code change information"
error_parse="Unable to Parse"
error_na="NA"
error_email="vipintm@gmail.com" # debug email id

# files
riakbin="$WORKSPACE/riak_test/riak_test"
test_cases="$WORKSPACE/antidote/riak_test/*.erl"
antidote_bin="$HOME/rt/antidote/current/dev/dev*/bin/antidote"
riak_configf="$HOME/.riak_test.config"
git_prv_key="$HOME/.git.prv.dsa"
git_pub_key="$HOME/.git.pub.dsa"
antidote_current="$WORKSPACE/antidote/riak_test/bin/antidote-current.sh"
antidote_setup="$WORKSPACE/antidote/riak_test/bin/antidote-setup.sh"
code_histroy="$HOME/.code_histroy"
# Property Files 
exportPopertyFile="$WORKSPACE/envpro/general.properties"
exportBuildFile="$WORKSPACE/envpro/ft_build.properties"

# exit 1
echo "ft_BUILD_RESULT=ABORTED" > $exportBuildFile
echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile

# Vars
is_timeout=0
is_perl=0
is_awk=0
is_sed=0
is_erl=0
is_erlc=0
is_git=0
is_grep=0
is_git=0
riak_changed=0
antidote_changed=0
test_pass_cnt=0
test_failed_cnt=0
test_cnt=0
declare -a failed_fns
declare -a failed_errors

# Time out
max_time=3600 #in seconds
# dev nos
default_dev_nos=6 #default
dev_nos=6 
mak_dev_nos=6
conf_dev_nos=0

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
if type "git" > /dev/null 2>&1 ; then
	is_git=1
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

# select time 
if [ "$is_timeout" -eq 1 ]; then
	echo "Using bash timeout function ..."
	function alarm() { timeout "$@"; }
    echo "Using date for local time function ..."
    function local_time_fn() { date; }    
elif [ "$is_perl" -eq 1 ] ; then
	echo "Using perl script for timeout function ..."
	function alarm() { perl -e 'alarm shift; exec @ARGV' "$@"; }
    echo "Using perl script for local time function ..."
    function local_time_fn() { perl -MPOSIX -le 'print strftime "%D %T", localtime $^T'; }
else
	echo "Time out support not found ..."
    echo "WARNING : The test will run as log the Jenkins KILLs it ..."
    function alarm() { bash "${@:2}"; }
    echo "WARNING : Using a dummy time ..."
    function local_time_fn() { echo "Di 10. Nov 17:28:23 CET 2015"; }
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

# git key file
function gen_git_prv_key()
{
  echo "Creating/Updating git deploy prv key .."
  cat > $git_prv_key << EOL
-----BEGIN DSA PRIVATE KEY-----
MIIBvAIBAAKBgQDZd+UKa8xy1oZ+hvps9HeBVwe9NTBU03JDFYmh9sUmpfEggvRZ
BIlb+MqY/rUQRq4D9BQyiS9IahP/iArPHOy5Inj8b+ryUwpBE7N+uxThyjIGThpg
roByP3WAZwiX0BWaN2wTYsfz7HBkoyJrbBzmzLQOhuXcNz/C4BWqnK1lVwIVANsV
VXMY/c9icdq4PZhQwb1pd2TDAoGBAKnv/j97wmzR06HFD9WHXTwstoXqk9060Sqt
XPDhUJ1+WOW+ovoxsdgzX6MnPTEH4QI/3BedUazSJFPajI35+V38tQEqIkBS8YnP
F6QI/Je6SEnu0nzzSnrF2c1zcmDrsttv1Df8oijDeEYppMkWvVE/PsiDgFkIilJr
UacUw9IDAoGAedzp1fYfpX4eBuVSGaJpHYWs58LMJuvVTV3Y22kcyFrsohtbJXFC
7cB12YaSkcDuc0alkdeCedXDT4K7xpIXS0iwxfYyRjuP1k9f2Lwc0Dn7h8qwnGb6
d3BmhbRKbrBB9BSHwaw4YJE6Xge1gmzqwQgLuFHuT/0ooJpd3NMFHrwCFQDQNUBT
G/6e/WjiC+pDTQ9CtJiKJw==
-----END DSA PRIVATE KEY-----
EOL
}

# git key file
function gen_git_pub_key()
{
  echo "Creating/Updating git deploy pub key .."
  cat > $git_prv_key << EOL
ssh-dss AAAAB3NzaC1kc3MAAACBANl35QprzHLWhn6G+mz0d4FXB701MFTTckMVia\
H2xSal8SCC9FkEiVv4ypj+tRBGrgP0FDKJL0hqE/+ICs8c7LkiePxv6vJTCkETs367\
FOHKMgZOGmCugHI/dYBnCJfQFZo3bBNix/PscGSjImtsHObMtA6G5dw3P8LgFaqcrW\
VXAAAAFQDbFVVzGP3PYnHauD2YUMG9aXdkwwAAAIEAqe/+P3vCbNHTocUP1YddPCy2\
heqT3TrRKq1c8OFQnX5Y5b6i+jGx2DNfoyc9MQfhAj/cF51RrNIkU9qMjfn5Xfy1AS\
oiQFLxic8XpAj8l7pISe7SfPNKesXZzXNyYOuy22/UN/yiKMN4RimkyRa9UT8+yIOA\
WQiKUmtRpxTD0gMAAACAedzp1fYfpX4eBuVSGaJpHYWs58LMJuvVTV3Y22kcyFrsoh\
tbJXFC7cB12YaSkcDuc0alkdeCedXDT4K7xpIXS0iwxfYyRjuP1k9f2Lwc0Dn7h8qw\
nGb6d3BmhbRKbrBB9BSHwaw4YJE6Xge1gmzqwQgLuFHuT/0ooJpd3NMFHrw= Jenkins

EOL

git_ssh_key="ssh-dss AAAAB3NzaC1kc3MAAACBANl35QprzHLWhn6G+mz0d4FXB\
701MFTTckMVia\
H2xSal8SCC9FkEiVv4ypj+tRBGrgP0FDKJL0hqE/+ICs8c7LkiePxv6vJTCkETs367\
FOHKMgZOGmCugHI/dYBnCJfQFZo3bBNix/PscGSjImtsHObMtA6G5dw3P8LgFaqcrW\
VXAAAAFQDbFVVzGP3PYnHauD2YUMG9aXdkwwAAAIEAqe/+P3vCbNHTocUP1YddPCy2\
heqT3TrRKq1c8OFQnX5Y5b6i+jGx2DNfoyc9MQfhAj/cF51RrNIkU9qMjfn5Xfy1AS\
oiQFLxic8XpAj8l7pISe7SfPNKesXZzXNyYOuy22/UN/yiKMN4RimkyRa9UT8+yIOA\
WQiKUmtRpxTD0gMAAACAedzp1fYfpX4eBuVSGaJpHYWs58LMJuvVTV3Y22kcyFrsoh\
tbJXFC7cB12YaSkcDuc0alkdeCedXDT4K7xpIXS0iwxfYyRjuP1k9f2Lwc0Dn7h8qw\
nGb6d3BmhbRKbr\
BB9BSHwaw4YJE6Xge1gmzqwQgLuFHuT/0ooJpd3NMFHrw= Jenkins"
}

# riak config file
function gen_riak_config()
{
  if [ -f $riak_configf ]
  then
      echo "The riak test config file found"
      cat $riak_configf
      echo ""
  else
      echo "Creating/Updating the riak test config file($dev_nos) .."
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
    {num_nodes, $dev_nos},
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

}

# dir chmod
function set_path_chmod()
{
	chmod -R 755 $WORKSPACE/riak_test
	chmod -R 755 $WORKSPACE/antidote
}

# clean old files
function clean_old_logs()
{
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

	if [ -d $WORKSPACE/envpro ]; then
		echo "Clearing old env files ..."
    	rm -rf $WORKSPACE/envpro/*.properties
	else
		echo "Creating send dir ..."
		mkdir $WORKSPACE/envpro
	fi
	if [ -d $WORKSPACE/ft_send ]; then
		echo "Clearing old send files ..."
    	rm -rf $WORKSPACE/ft_send/*.txt
	else
		echo "Creating env dir ..."
		mkdir $WORKSPACE/ft_send
	fi    
    # exit 1
	echo "ft_BUILD_RESULT=FAILED" > $exportBuildFile
	echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
}


# Collect time
SDATE=$(local_time_fn)
echo "build_time=$SDATE" >> $exportPopertyFile

if [ "$is_git" -eq 0 ] 
then
	echo "Git not found ..."
else
	git --version
fi

gen_git_prv_key
gen_git_pub_key

set_path_chmod

clean_old_logs

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
        echo "ft_BUILD_RESULT=ABORTED" > $exportBuildFile
		echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
        echo "build_exit_code=Unable to read $antidote_current" >> $exportPopertyFile
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
        echo "ft_BUILD_RESULT=ABORTED" > $exportBuildFile
		echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
        echo "build_exit_code=Unable to read $antidote_setup" >> $exportPopertyFile        
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
rt_dev_loc="$HOME/rt/antidote/current/dev"
echo " " > $WORKSPACE/tlog/ft_test_dev_logs.log

# dir chmod
chmod -R 755 $HOME/rt

# requirment test -2
if [ -f "$riakbin" ] 
then
    echo "Found antidote bin in place ..."
else
	echo "Required support (antidote bin) not found, exiting ..."
    echo "ft_BUILD_RESULT=ABORTED" > $exportBuildFile
	echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
    echo "build_exit_code=Required support (antidote bin) not found, exiting" >> $exportPopertyFile    
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
    	riak_branch_history="Found a sucessfull test with this riak branch"
  		riak_HEAD_old=$(cat $code_histroy/riak_test/$riak_name/sHEAD 2>/dev/null)
    else
    	riak_branch_history="Not Found a sucessfull test with this riak branch"
	fi
else
	riak_branch_history="Running first time with this branch"
	mkdir -p $code_histroy/riak_test/$riak_name
fi
echo "$riak_branch_history ..."

echo "riak_branch=$riak_name" >> $exportPopertyFile
echo "riak_branch_history=$riak_branch_history" >> $exportPopertyFile

#
antidote_HEAD_old="$error_na"
antidote_HEAD=$(cat $WORKSPACE/antidote/.git/HEAD)
antidote_name=$(cat $WORKSPACE/antidote/.git/FETCH_HEAD | grep -w "$antidote_HEAD" | cut -d"'" -f2)
echo "Using antidote branch : $antidote_name"
if [ -d $code_histroy/antidote/$antidote_name ]
then
	if [ -f $code_histroy/antidote/$antidote_name/sHEAD ]
	then
    	antidote_branch_history="Found a sucessfull test with this antidote branch"
   		antidote_HEAD_old=$(cat $code_histroy/antidote/$antidote_name/sHEAD 2>/dev/null)
    else
    	antidote_branch_history="Not Found a sucessfull test with this antidote branch"
	fi
else
	antidote_branch_history="Running first time with this branch"
	mkdir -p $code_histroy/antidote/$antidote_name
fi
echo "$antidote_branch_history ..."

echo "antidote_branch=$antidote_name" >> $exportPopertyFile
echo "antidote_branch_history=$antidote_branch_history" >> $exportPopertyFile

# requirment test -3
is_antidote_bin=$(ls -1 $antidote_bin 2>/dev/null \
	| wc -l | sed 's/^ *//g')
# find the dev no
if [ -f $WORKSPACE/antidote/Makefile ] ; then
	mak_dev_nos=$(cat $WORKSPACE/antidote/Makefile | grep -e ^DEVNODES | cut -d"=" -f2 | sed 's/^ *//g')
    echo "Dev nos in antidote Makefile : $mak_dev_nos"
else
	echo "Unable to read Makefile ..."
    echo "Considring mak_dev_nos = default_dev_nos .."
    mak_dev_nos=$default_dev_nos
fi
if [ -f $riak_configf ] ; then
	conf_dev_nos=$(cat $riak_configf | grep "{num_nodes" | cut -d"," -f2 | cut -d"}" -f1 | sed 's/^ *//g')
    echo "Dev nos in riak conffile     : $conf_dev_nos"
else
	# taking 999 to regenarate config file
	conf_dev_nos=999
fi
#
if [ "$mak_dev_nos" -lt "$default_dev_nos" ]
then
    dev_message="The test is run with less dev nos $mak_dev_nos than default $default_dev_nos"
    echo "WARNING : $dev_message ..."
else
	dev_message="."
fi
#
if [ "$is_antidote_bin" -ge "$mak_dev_nos" ]
then
	echo "Found antidote dev nodes ( $is_antidote_bin ) ..."
else
	echo "Not found antidote devs ..."
    exit 1
fi
#
if [ "$conf_dev_nos" -eq "$mak_dev_nos" ]
then
	echo "Required dev nos found in riak config file ..."
else
	echo "Required dev nos not found in riak config file ..."
	dev_nos=$mak_dev_nos
	if [ -f "$riak_configf" ]
	then
		rm -f $riak_configf
	fi
	gen_riak_config
	if [ -f "$riak_configf" ]
	then
		echo "Updated Dev nos in configfile with $mak_dev_nos ..."
	else
		echo "Problem in updating configfile ..."
    	echo "ft_BUILD_RESULT=ABORTED" > $exportBuildFile
		echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
    	echo "build_exit_code=Problem in updating configfile" >> $exportPopertyFile         
        # without config file test will not run - don't remove
		exit 1
	fi
fi

echo "mak_dev_nos=$mak_dev_nos" >> $exportPopertyFile
echo "default_dev_nos=$default_dev_nos" >> $exportPopertyFile
echo "is_antidote_bin=$is_antidote_bin" >> $exportPopertyFile
echo "conf_dev_nos=$conf_dev_nos" >> $exportPopertyFile
echo "dev_message=$dev_message" >> $exportPopertyFile

# clean old dev's
clean_dev

##### test loop
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

		echo " " >> $WORKSPACE/tlog/ft_test_dev_logs.log
    	echo "$log_sep"
    	echo "## Test : $fn_test" >> $WORKSPACE/tlog/ft_test_dev_logs.log
		for name_dev in $(ls -d -1 $rt_dev_loc/*)
    	do
    		if [ -d $name_dev ]
        	then
        		echo " " >> $WORKSPACE/tlog/ft_test_dev_logs.log
            	echo "Files from : $name_dev " >> $WORKSPACE/tlog/ft_test_dev_logs.log
            	echo " " >> $WORKSPACE/tlog/ft_test_dev_logs.log
        		for name_dev_log in $(ls -1 $name_dev/log/*.*)
            	do
                	echo "File name : $name_dev_log" >> $WORKSPACE/tlog/ft_test_dev_logs.log
                	echo " " >> $WORKSPACE/tlog/ft_test_dev_logs.log
                	cat $name_dev_log >> $WORKSPACE/tlog/ft_test_dev_logs.log
                	echo " " >> $WORKSPACE/tlog/ft_test_dev_logs.log
        		done
    		fi
     	done
	
	fi 

    if [ -f  $utest_file ]
    then
    	echo "Test result file (xml) created ..."
    	cat $utest_file
    else
    	echo "Error in test result file (xml) creation ..."
    fi

done
##### test loop end

# Collecting Code Change information
#
ft_riak_change_log=""
echo ""
echo $log_sep
echo "Code change info ..."
riak_log="$WORKSPACE/tlog/riak_git_change.log"
if [ "$riak_HEAD" != "$riak_HEAD_old" ] 
then
	if [ "$is_git" -eq 1 ] ; then
    	echo "Found code diffrance (b:$riak_name) for riak ..."
    	cd $WORKSPACE/riak_test
        if [ "$error_na" != "$riak_HEAD_old" ]
        then
        	echo "Generating code diff info from last successful test ..."
        	echo "Change Log :" > $riak_log
            echo " " >> $riak_log
            git log "$riak_HEAD_old".."$riak_HEAD" >> $riak_log
            riak_blame_email=$(git log "$riak_HEAD_old".."$riak_HEAD" \
            | grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' \
            | sort -u | tr -d '\n' | tr '\n' ',')
            ft_riak_change_log="Changes        : https://github.com/SyncFree/riak_test/compare/$riak_HEAD_old...$riak_HEAD"
        else
        	echo "No previous successful head info found, generating diff for last 5 changes ..."
        	echo "Change Log (last 5) :" > $riak_log
            echo " " >> $riak_log
   			git log -n5 >> $riak_log
            riak_blame_email=$(git log -n5 \
            | grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' \
            | sort -u | tr -d '\n' | tr '\n' ',')
        fi
    else
    	echo "Unable to get the code diffrance (b:$riak_name) for riak ..."
    	echo "Change Log          :" > $riak_log
    	echo "$error_cc" >> $riak_log
        riak_blame_email="$error_email"
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
    riak_blame_email="$error_email"
fi    

#
ft_antidote_change_log=""
lastKnownGitAs="NA"
antidote_log="$WORKSPACE/tlog/antidote_git_change.log"
if [ "$antidote_HEAD" != "$antidote_HEAD_old" ]
then
    if [ "$is_git" -eq 1 ] ; then
    	echo "Found code diffrance (b:$antidote_name) for antidote ..."
    	cd $WORKSPACE/antidote
        if [ "$error_na" != "$antidote_HEAD_old" ]
        then
        	echo "Generating code diff info from last successful test ..."
        	echo "Change Log :" > $antidote_log
            echo " " >> $antidote_log
        	git log "$antidote_HEAD_old".."$antidote_HEAD" >> $antidote_log
            antidote_blame_email=$(git log "$antidote_HEAD_old".."$antidote_HEAD" \
            | grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' \
            | sort -u | tr -d '\n' | tr '\n' ',')
            ft_antidote_change_log="Changes        : https://github.com/SyncFree/antidote/compare/$antidote_HEAD_old...$antidote_HEAD"
        else
        	echo "No previous successful head info found, generating diff for last 5 changes ..."
        	echo "Change Log (last 5) :" > $antidote_log
            echo " " >> $antidote_log
        	git log -n5 >> $antidote_log
            antidote_blame_email=$(git log -n5 \
            | grep -i -o '[A-Z0-9._%+-]\+@[A-Z0-9.-]\+\.[A-Z]\{2,4\}' \
            | sort -u | tr -d '\n' | tr '\n' ',')
        fi
    else
    	echo "Unable to get the code diffrance (b:$antidote_name) for antidote ..."
    	echo "Change Log          :" > $antidote_log
    	echo "$error_cc" >> $antidote_log
        antidote_blame_email="$error_email"
    fi
   	antidote_changed=1
    if [ "$test_pass_cnt" -eq "$test_cnt" ]
	then
		echo "Updating the successful head (b:$antidote_name) info for antidote ..."
		cp $WORKSPACE/antidote/.git/HEAD $code_histroy/antidote/$antidote_name/sHEAD
    else
    	if [ -f $code_histroy/antidote/$antidote_name/sHEAD ]
        then
    		lastKnownGitAs=$(cat $code_histroy/antidote/$antidote_name/sHEAD)
        fi
	fi
else
	echo "No code diffrance (b:$antidote_name) for antidote from last successful test ..."
	antidote_changed=0
    antidote_blame_email="$error_email"
fi

CSV_DATA="$BUILD_NUMBER,$test_cnt,$test_pass_cnt,$test_failed_cnt,$SDATE"
echo $CSV_DATA >> $code_histroy/antidote/$antidote_name/tResults.csv
echo $CSV_DATA >> $code_histroy/antidote/AgResults.csv

# Push to  env

#
echo "ft_riak_change_log=$ft_riak_change_log" >> $exportPopertyFile
echo "ft_antidote_change_log=$ft_antidote_change_log" >> $exportPopertyFile

echo "Changes riak git url : $ft_riak_change_log"
echo "Changes antidote git url : $ft_antidote_change_log"

#
echo "lastKnownGitAs=$lastKnownGitAs" >> $exportPopertyFile

#
if [ "$error_email" != "$antidote_blame_email" ] && [ "$error_email" != "$riak_blame_email" ]
then
	ft_blame_email="$antidote_blame_email,$riak_blame_email"
    
elif [ "$error_email" == "$antidote_blame_email" ] && [ "$error_email" != "$riak_blame_email" ]
then
	ft_blame_email="$riak_blame_email"
    
elif [ "$error_email" != "$antidote_blame_email" ] && [ "$error_email" == "$riak_blame_email" ]
then
	ft_blame_email="$antidote_blame_email"
    
elif [ "$error_email" == "$antidote_blame_email" ] && [ "$error_email" == "$riak_blame_email" ]
then
	ft_blame_email="$error_email"
    
else
	echo "Unable to find upstream commiters email "
    echo "or there is no change from last sucessful test ..."
    ft_blame_email="$error_email"
fi

echo "upstream commiters email : $ft_blame_email"
echo "ft_blame_email=$ft_blame_email" >> $exportPopertyFile

# 
ft_thisBuild="unknown"
ft_RedAlert=""
ft_thisBuildCount=0
#
if [ "$test_pass_cnt" -ne "$test_cnt" ]
then
	
	if [ -f $code_histroy/antidote/$antidote_name/sBuild ]
    then
        echo "0" > $code_histroy/antidote/$antidote_name/sCount
        ft_thisBuildfCount="1"
        echo "ft_thisBuildfCount" > $code_histroy/antidote/$antidote_name/fCount    
    	ft_thisBuild="The overall test status is changed from PASSED to FAILED"
        ft_RedAlert="WARNING : Latest code changes made tests to fail"
    	cp $code_histroy/antidote/$antidote_name/sBuild $code_histroy/antidote/$antidote_name/lsBuild

    elif [ -f $code_histroy/antidote/$antidote_name/fBuild ]
    then
        ft_thisBuildfCount=$(cat $code_histroy/antidote/$antidote_name/fCount)
        ft_thisBuildfCount=$((ft_thisBuildfCount+1))
        echo "ft_thisBuildfCount" > $code_histroy/antidote/$antidote_name/fCount    
    	ft_thisBuild="The overall test status is still FAILED (last $ft_thisBuildfCount)"
        ft_RedAlert=""    	
        cp $code_histroy/antidote/$antidote_name/fBuild $code_histroy/antidote/$antidote_name/lfBuild
        
    else
    	ft_thisBuild="The overall test status is FAILED (from unknown / first time)"
        ft_RedAlert=""     
        ft_thisBuildfCount="1"
        echo "ft_thisBuildfCount" > $code_histroy/antidote/$antidote_name/fCount
        
    fi
    echo $BUILD_NUMBER > $code_histroy/antidote/$antidote_name/fBuild
    if [ -f $code_histroy/antidote/$antidote_name/lsBuild ]
    then
    	lastKnownBuild=$(cat $code_histroy/antidote/$antidote_name/lsBuild)
    else
    	lastKnownBuild="unknown"
    fi
    ft_thisBuildCount=$ft_thisBuildfCount
    
else

	if [ -f $code_histroy/antidote/$antidote_name/fBuild ]
    then
        echo "0" > $code_histroy/antidote/$antidote_name/fCount
        ft_thisBuildsCount="1"
        echo "ft_thisBuildsCount" > $code_histroy/antidote/$antidote_name/sCount     
    	ft_thisBuild="The overall test status is changed from FAILED to PASSED"
        ft_RedAlert="Latest code changes made tests to pass"      
    	cp $code_histroy/antidote/$antidote_name/fBuild $code_histroy/antidote/$antidote_name/lfBuild
        
    elif [ -f $code_histroy/antidote/$antidote_name/sBuild ]
    then
        ft_thisBuildsCount=$(cat $code_histroy/antidote/$antidote_name/sCount)
        ft_thisBuildsCount=$((ft_thisBuildsCount+1))
        echo "ft_thisBuildsCount" > $code_histroy/antidote/$antidote_name/sCount      
    	ft_thisBuild="The overall test status is still PASSED (last $ft_thisBuildsCount)"
        ft_RedAlert=""     
        cp $code_histroy/antidote/$antidote_name/sBuild $code_histroy/antidote/$antidote_name/lsBuild
     
    else
    	ft_thisBuild="The overall test status is PASSED (from unknown / first time)"
        ft_RedAlert=""     
        ft_thisBuildsCount="1"
        echo "ft_thisBuildsCount" > $code_histroy/antidote/$antidote_name/sCount
        
    fi
    echo $BUILD_NUMBER > $code_histroy/antidote/$antidote_name/sBuild
    if [ -f $code_histroy/antidote/$antidote_name/lfBuild ]
    then
    	lastKnownBuild=$(cat $code_histroy/antidote/$antidote_name/lfBuild)
    else
    	lastKnownBuild="unknown"
    fi
   	ft_thisBuildCount=$ft_thisBuildsCount
fi

echo "ft_thisBuild=$ft_thisBuild" >> $exportPopertyFile
echo "ft_RedAlert=$ft_RedAlert" >> $exportPopertyFile
echo "lastKnownBuild=$lastKnownBuild" >> $exportPopertyFile
echo "ft_thisBuildCount=$ft_thisBuildCount" >> $exportPopertyFile

echo "Test status : $ft_thisBuild"
echo "Red Alert : $ft_RedAlert"
echo "Last known build : $lastKnownBuild"
echo "This state build : $ft_thisBuildCount"

#
test_failed_name=$(IFS=, ; echo "${failed_fns[*]}")
echo "test_failed_name=$test_failed_name" >> $exportPopertyFile

# Summary
echo ""
echo ""
echo "################ Summary ####################"
echo ""
echo ""
echo $log_sep
echo "# riak_test" 
echo "branch              : $riak_name"	
if [ "$riak_changed" -eq 1 ]
then
    if [ "$riak_changed" -gt 0 ]
    then
    	cat $riak_log
    	echo ""
        cp $riak_log $WORKSPACE/ft_send/riak_git_change_log.txt
    else
    	echo ""
    fi
    echo "riak_branch_changed=Change found" >> $exportPopertyFile
else
	echo "Change Log          : No change found"
    echo ""
    echo "riak_branch_changed=No change found" >> $exportPopertyFile
fi

echo $log_sep
echo "# antidote"
echo "branch              : $antidote_name"
if [ "$antidote_changed" -eq 1 ]
then
    if [ "$antidote_changed" -gt 0 ]
    then
    	cat $antidote_log
    	echo ""
        cp $antidote_log $WORKSPACE/ft_send/antidote_git_change_log.txt
    else
    	echo ""
    fi
    echo "antidote_branch_changed=Change found" >> $exportPopertyFile
else
	echo "Change Log          : No change found"
    echo ""
    echo "antidote_branch_changed=No change found" >> $exportPopertyFile
fi


ft_error_log="$WORKSPACE/tlog/ft_error.log"
echo $log_sep
if [ "$mak_dev_nos" -lt "$default_dev_nos" ]
then
    echo "WARNING : The test is run with less dev nos ($mak_dev_nos < $default_dev_nos)"
    echo "          Update in Makefile"
fi
echo "Total no of tests   :$test_cnt" 
echo "test_cnt=$test_cnt" >> $exportPopertyFile
echo "No of tests passed  :$test_pass_cnt"
echo "test_cnt=$test_cnt" >> $exportPopertyFile
echo "test_pass_cnt=$test_pass_cnt" >> $exportPopertyFile

if [ "$test_pass_cnt" -ne "$test_cnt" ]
then
	echo "No of tests failed  :$test_failed_cnt"
    echo "test_failed_cnt=$test_failed_cnt" >> $exportPopertyFile
    cp $WORKSPACE/tlog/ft_test_dev_logs.log $WORKSPACE/ft_send/dev_logs.txt
    loop_cnt=0
    echo ""
    echo $log_sep
    echo "Failed tests summary -"
    echo "" > $ft_error_log
    for failed_fn_name in "${failed_fns[@]}"
    do
    	error_temp="0"
    	echo "# $failed_fn_name" 
        echo "# $failed_fn_name" >> $ft_error_log
        error_temp="${failed_errors[$loop_cnt]}"
        #there is somthing in first few characters
        is_error=$(echo ${error_temp:2:6})
        if [ -z $is_error ]
        then
        	echo "Unable to parse error info, refer the build log ($BUILD_URL)"
            echo "Unable to parse error info, refer the build log ($BUILD_URL)" >> $ft_error_log
        else
			echo -e "Error : ${failed_errors[$loop_cnt]}"
            echo -e "Error : ${failed_errors[$loop_cnt]}" >> $ft_error_log
        fi
        echo "" 
        echo "" >> $ft_error_log
        loop_cnt=$((loop_cnt+1))
    done
    echo "Marking as FAILED"
    echo $log_sep
    echo ""
	cp $ft_error_log $WORKSPACE/ft_send/test_error_logs.txt
    echo "ft_BUILD_RESULT=FAILED" >> $exportBuildFile
    echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
    echo "build_exit_code=All tests are not passed" >> $exportPopertyFile
else
	echo "test_failed_cnt=0" >> $exportPopertyFile
	echo "Marking as PASSED"
    echo $log_sep
    echo ""
    echo "ft_BUILD_RESULT=PASSED" >> $exportBuildFile
    echo "ft_BUILD_NUMBER=$BUILD_NUMBER" >> $exportBuildFile
    echo "build_exit_code=All tests are passed" >> $exportPopertyFile
fi

