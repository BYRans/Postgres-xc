#!/bin/bash

function cancelOutput(){
        logFile=expect_log_temp_`date +%Y%m%d%H%M%S`
        for line in `cat $1`
        do  
                port=`echo $line|sed 's/|.*//g'`
                host=`echo $line|sed 's/.*|//g'`
                name=`echo $line|sed 's/|/+/'|sed 's/.*+//g'|sed 's/|.*//'`
                /usr/bin/ssh $host "netstat -anp|grep $port" > $logFile
                ifExist=`grep "LISTEN" $logFile`
                if [ "$ifExist" =  "" ];then
                        echo -e "$host:$port\t$name\tdisabled" >> $2
                else
                        echo -e "$host:$port\t$name\tactive" >> $2
                fi  
        done
	rm -f $logFile
}

if (( $# < 3 )); then
    echo "参数输入格式为：host port DBUser。host是要连接的服务器ip，port是服务端口号，DBUser是Swift数据库用户名。"
    exit
fi
hostPortFile=host_port_temp_`date +%Y%m%d%H%M%S`
psql -h $1 -p $2 -U $3 postgres -o $hostPortFile << EOF
    select node_port,node_name,node_host from pgxc_node;
EOF
sed -i 's/ //g' $hostPortFile
sed -i '/^[^0-9]/d' $hostPortFile
sed -i '/^$/d' $hostPortFile

if ! [ -s $hostPortFile ];then
    echo "登录数据库失败。输入参数有误或数据库未启动。"
    rm -f $hostPortFile
    exit
fi

tempFile=monitor_temp_`date +%Y%m%d%H%M%S`
resultFile=monitor_result_`date +%Y%m%d%H%M%S`

cancelOutput $hostPortFile $resultFile > $tempFile

cat $resultFile

rm -f $tempFile
rm -f $hostPortFile
rm -f $resultFile
