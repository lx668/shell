#!/bin/bash
# Auth：lx
# Version：0.1
# Ctime：2016-09-02 
# Node List
PRE_LIST=(lx@192.168.56.11)
ROLLBACK_LIST="lx@192.168.56.11"

# Date/Time Veriables
LOG_DATE='date "+%Y-%m-%d"'
LOG_TIME='date "+%H-%M-%S"'
CTIME=$(date "+%Y-%m-%d")-$(date "+%H-%M-%S")


# Shell Env
SHELL_DIR="/data/command"
SHELL_NAME="deploy_all.sh"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

# Code Env
WAR_NAME="$3-1.0.0.war"
echo $WAR_NAME
CODE_DIR="/data/code/"
#CODE_DIR="/data/code/chaos"
LOCK_FILE="/tmp/deploy.lock"

usage(){
	echo $"Usage: $0 {deploy project | rollback project [ list | version ]"
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
	cd $CODE_DIR/$1 && git pull && mvn clean install
	PRO_NAME=`find $CODE_DIR/$1 -name "$WAR_NAME"`
}


code_scp(){
	writelog "code_scp"
	for node in $PRE_LIST;do
		ssh $node "mkdir -p /opt/webroot/$1/$2$CTIME"
		scp $PRO_NAME $node:/opt/webroot/$1/$2$CTIME
	done
}

pre_deploy(){
	writelog "remove from cluster"
        ssh $PRE_LIST "cd /opt/webroot/$1/$2$CTIME && jar xf $WAR_NAME"
	ssh $PRE_LIST "cd /opt/webroot/$1/$2$CTIME && rm -f $WAR_NAME"
        ssh $PRE_LIST "rm -f /data/services/tomcat-$2/webapps/ROOT && ln -s /opt/webroot/$1/$2$CTIME /data/services/tomcat-$2/webapps/ROOT"
	ssh $PRE_LIST "sh /data/services/tomcat-$2/bin/restart.sh"
}


rollback_fun(){
	for node in $ROLLBACK_LIST;do
		ssh $node "rm -f /data/services/tomcat-$2/webapps/ROOT && ln -s /opt/webroot/$1/$3 /data/services/tomcat-$2/webapps/ROOT"
		ssh $PRE_LIST "sh /data/services/tomcat-$2/bin/restart.sh"
    	done
}

rollback(){
	if [ -z $3 ];then
   		shell_unlock;		
		Last_version=`lx@192.168.56.11 "ls -lrtd /opt/webroot/$1/$2*|tail -2|head -1"|awk -F "[ /]+" '{print $NF}'`
    		#echo "Please input rollback version" && exit;
		echo $Last_version
		echo "===================================================================================="
		rollback_fun $1 $2 $Last_version
	else
		case $1 in
        	list)
			ssh $PRE_LIST "ls -ld /opt/webroot/$1/$2*"
		;;
		*)
			rollback_fun $1 $3
    	esac
	fi
}

main(){
   if [ -f $LOCK_FILE ];then
	echo "Deploy is running" && exit;
   fi
    DEPLOY_METHOD=$1
    PROJECT_NAME=$2
    DIR_NAME=$3
    ROLLBACK_VER=$4
    case $DEPLOY_METHOD in
       deploy)
		shell_lock;
		code_get $PROJECT_NAME;
		code_scp $PROJECT_NAME $DIR_NAME;
		pre_deploy $PROJECT_NAME $DIR_NAME;
		shell_unlock;
		;;
	rollback)
		shell_lock;
		rollback $PROJECT_NAME $DIR_NAME $ROLLBACK_VER;
		shell_unlock;
		;;
	*)
		usage;
    esac
}
main $1 $2 $3 $4
