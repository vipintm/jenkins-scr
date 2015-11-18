#!/bin/bash

WORKSPACE=$(pwd)
JENKINS_URL="http://jenkins.lip6.fr"
JENKINS_JOBS="antidote,riak_test,ft_antidote"
COMMIT_MSG=$(date)

is_java=0
is_git=0

is_jenkins_cli=0
is_auth=0

if type "java" > /dev/null 2>&1 ; then
	is_java=1
    	java -version
fi

if type "git" > /dev/null 2>&1 ; then
	is_git=1
    	git --version
fi

function clean_old_logs()
{
	if [ -d $WORKSPACE/ft_bin ]; then
		echo "Clearing old bin files ..."
    	rm -rf $WORKSPACE/ft_bin/*.*
	else
		echo "Creating bin dir ..."
		mkdir $WORKSPACE/ft_bin
	fi
}

function get_jenkins_cli()
{
	if [ "$is_java" -eq 0 ] 
	then
		echo "Java not found ..."
		echo "jenkins-cli need java ..."
	else
    		if [ -f $WORKSPACE/ft_bin/jenkins-cli.jar ]
		then
			echo "jenkins-cli found ..."
			is_jenkins_cli=1
		else
                        echo "jenkins-cli not found ..."
			is_jenkins_cli=0
			echo "Downloading ..."
			cd $WORKSPACE/ft_bin/
			wget $JENKINS_URL/jnlpJars/jenkins-cli.jar > /dev/null 2>&1
			cd $WORKSPACE	
		fi
	fi
}

function jenkins-cli_run()
{
	if [ "$is_java" -eq 1 ] && [ "$is_jenkins_cli" -eq 1 ]
	then
		java -jar $WORKSPACE/ft_bin/jenkins-cli.jar -s $JENKINS_URL/ $@
	else
		exit 1
    	fi
}

function check_jenkins_auth()
{	
	is_auth=$(jenkins-cli_run who-am-i | grep "authenticated" | wc -l)
	if [ "$is_auth" -eq 1 ]
	then
		echo "The jenkins is authanticated ..."
	else
		echo "The jenkins is not authaticated ($is_auth) ..."
		is_auth=0
	fi
}

function get_all_jobs()
{
        if [ "$is_auth" -eq 1 ] 
        then
		for temp_jobs in $(echo $JENKINS_JOBS | sed "s/,/ /g")
		do
    			jenkins-cli_run get-job $temp_jobs >  $WORKSPACE/$temp_jobs/job.xml 
		done
	else
		exit 1
	fi
}

function get_plugins()
{
        if [ "$is_auth" -eq 1 ]
        then
                jenkins-cli_run list-plugins >  $WORKSPACE/list-plugins.md
        else
                exit 1
        fi
}

function git_commit()
{
	if [ "$is_git" -eq 1 ]
	then
		for temp_file in $(git diff --name-only)
		do
			git commit -m"$COMMIT_MSG" $temp_file
		done
	else
		exit 1
	fi		
}

function git_push()
{
        if [ "$is_git" -eq 1 ]
        then
                git push
        else
                exit 1
        fi
}

### MAIN ###

clean_old_logs
until [  $is_jenkins_cli -eq 1 ]
do
	get_jenkins_cli
done
check_jenkins_auth
get_all_jobs
get_plugins


git_commit
git_push
