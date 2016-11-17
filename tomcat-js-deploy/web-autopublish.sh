#!/bin/bash
WAR_PATH="/data/www/war"
SITE_PATH="/data/www/site"
TOMCAT_PATH="/data/services/apache-tomcat-8.5.4/"
PROJECT_NAME="bi-web"
cd /data/code/chaos
git pull
mvn clean install -Pprod -Dmaven.test.skip=true
cd $PROJECT_NAME/
mvn clean install -Pprod -Dmaven.test.skip=true
rm -rf $WAR_PATH/"$PROJECT_NAME".war
rm -rf $WAR_PATH/$PROJECT_NAME
mv target/$PROJECT_NAME-1.0.0.war $WAR_PATH/"$PROJECT_NAME".war
cp $WAR_PATH/"$PROJECT_NAME".war $WAR_PATH/backup/"$PROJECT_NAME".`date +%Y%m%d%H%M%S`.war
mkdir -p $WAR_PATH/$PROJECT_NAME
mv $WAR_PATH/"$PROJECT_NAME".war $WAR_PATH/$PROJECT_NAME/
cd $WAR_PATH/$PROJECT_NAME
jar xvf "$PROJECT_NAME".war
rm -rf "$PROJECT_NAME".war
cd $SITE_PATH
jps |grep Bootstrap|awk '{print $1}'|xargs kill -9
rm -rf $SITE_PATH/${PROJECT_NAME}
rm -rf $SITE_PATH/ROOT
rm -rf $TOMCAT_PATH/work/Catalina/localhost/${PROJECT_NAME}
mv $WAR_PATH/$PROJECT_NAME/ $SITE_PATH/${PROJECT_NAME}
ln -s $SITE_PATH/${PROJECT_NAME} $SITE_PATH/ROOT
scp -rP22 /opt/app/wecash/* root@10.169.27.36:/opt/www/
sh /data/command/replace.sh
sh $TOMCAT_PATH/bin/startup.sh
tail -f $TOMCAT_PATH/logs/catalina.out
