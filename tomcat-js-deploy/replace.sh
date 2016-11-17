#!/bin/bash
#set -x
PRO_DIR=/data/www/site/bi-web/WEB-INF/views
GIT_DIR=/data/code/static/
NGX_DIR=/opt/app/wecash/nginx/

copy(){
    for i in ${NGX_FILE[*]}
    do
	echo $i
    MIN_JS=(`find $GIT_DIR -name "$i.min.js"`)
		for j in ${MIN_JS[*]}
		do
			aa=`/usr/bin/cp $j $NGX_DIR$m-$n.js`
			#aa=`cp $j $NGX_DIR$GIT_DIR$m-$n.js`
		done
    done
}
#查找js文件
NAME_JSP=(`find $PRO_DIR -name "*.jsp"`)

#查找js文件，并赋值给后置变量"1"
FILE=(`find $PRO_DIR -name "*.jsp"|xargs sed -n 's@^.*<script .*net/\(.*\).js".*script>$@\1@gp'`)

#创建目录
NAME_DIR=(`find $PRO_DIR -name "*.jsp"|xargs sed -n 's@^<script .*net/\(.*\).js".*script>$@\1@gp'|xargs dirname`)
echo ${NAME_DIR[*]}
for ll in ${NAME_DIR[*]}
do
    /usr/bin/mkdir $NGX_DIR$ll -p
done


for m in ${FILE[*]}
do
    echo $m
    NGX_FILE=(`echo $m|awk -F "/" '{print $NF}'`)
    #echo ${NGX_FILE[*]}
    FILE_JS=(`cd $GIT_DIR && git log $m.js|head -1|awk '{print $2}'`)
    #echo ${FILE_JS[*]}
    for n in ${FILE_JS[*]}
    do
	echo $n
		for kk in ${NAME_JSP[*]}
		do
			sed -i "s#$m.js#$m-$n.js#g" $kk
		done
	copy
    done
done

