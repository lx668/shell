#!/bin/bash

# Node List
PRE_LIST=(bi@10.144.18.120)
ROLLBACK_LIST="bi@10.144.18.120"

# Date/Time Veriables
LOG_DATE='date "+%Y-%m-%d"'
LOG_TIME='date "+%H-%M-%S"'
CTIME=$(date "+%Y-%m-%d")-$(date "+%H-%M-%S")


# Shell Env
SHELL_DIR="/data/command"
SHELL_NAME="deploy_all.sh"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

# Code Env
WAR_NAME="bi-sts-1.0.0.war"
CODE_DIR="/data/code/chaos"
LOCK_FILE="/tmp/deploy.lock"

usage(){
	echo $"Usage: $0 {deploy | rollback [ list | version ]"
}

writelog(){
   LOGINFO=$1
   echo "${CDATE} ${CTIME}: ${SHELL_NAME} : ${LOGINFO} "  >> ${SHELL_LOG}
}

shell_lock(){
	touch ${LOCK_FILE}
}

shell_unlock(){
	rm -f ${LOCK_FILE}
}

code_get(){
	writelog "code_get"; 
	cd $CODE_DIR && git pull && mvn clean install
	PRO_NAME=`find $CODE_DIR/ -name "$WAR_NAME"`
}


code_scp(){
	writelog "code_scp"
	for node in $PRE_LIST;do
		ssh $node "mkdir /opt/webroot/bi-sts$CTIME"
		scp $PRO_NAME $node:/opt/webroot/bi-sts$CTIME
	done
}

pre_deploy(){
	writelog "remove from cluster"
        ssh $PRE_LIST "cd /opt/webroot/bi-sts$CTIME && jar xf $WAR_NAME"
	ssh $PRE_LIST "cd /opt/webroot/bi-sts$CTIME && rm -f $WAR_NAME"
        ssh $PRE_LIST "rm -f /data/services/tomcat-chaos/webapps/ROOT && ln -s /opt/webroot/bi-sts$CTIME /data/services/tomcat-chaos/webapps/ROOT"
	ssh $PRE_LIST "sh /data/services/tomcat-chaos/bin/restart.sh"
}


rollback_fun(){
	for node in $ROLLBACK_LIST;do
		ssh $node "rm -f /data/services/tomcat-chaos/webapps/ROOT && ln -s /opt/webroot/$1 /data/services/tomcat-chaos/webapps/ROOT"
		ssh $PRE_LIST "sh /data/services/tomcat-chaos/bin/restart.sh"
    	done
}

rollback(){
	if [ -z $1 ];then
   		shell_unlock;		
		Last_version=`ssh bi@10.144.18.120 "ls -lrtd /opt/webroot/bi-sts2016*|tail -2|head -1"|awk -F "[ /]+" '{print $NF}'`
    		#echo "Please input rollback version" && exit;
		echo $Last_version
		rollback_fun $Last_version
	else
		case $1 in
        	list)
			ssh $PRE_LIST "ls -ld /opt/webroot/bi-sts*"
		;;
		*)
			rollback_fun $1
    	esac
	fi
}

main(){
   if [ -f $LOCK_FILE ];then
	echo "Deploy is running" && exit;
   fi
    DEPLOY_METHOD=$1
    ROLLBACK_VER=$2
    case $DEPLOY_METHOD in
       deploy)
		shell_lock;
		code_get;
		code_scp;
		pre_deploy;
		shell_unlock;
		;;
	rollback)
		shell_lock;
		rollback $ROLLBACK_VER;
		shell_unlock;
		;;
	*)
		usage;
    esac
}
main $1 $2
