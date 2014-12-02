#!/bin/bash
#该脚本用于管理数据的存储周期。该脚本加入定时任务，脚本执行机器为coordinator所在服务器，并且该机器对其它服务器免登。

if (( $# < 6 ));then
	echo -e "参数输入顺序为：port DBUser DBName table column period\n  port   数据库服务器连接端口号\n  DBName 数据库超级管理员名\n  table  数据所在的表名\n  column 日期字段名\n  period  存储周期，参数格式为数字后加d或m,d代表天 m代表月以100天为例，输入参数格式为100d;以10个月为例，period参数格式为10m"
	exit
fi
period=$6
unit=${period:(-1)}
number=${period%?}

if ! [ -n "$(echo $number| sed -n "/^[0-9]\+$/p")" ]; then
	echo "period参数格式错误"
	exit
fi

if ! [[ "$unit" = "d" || "$unit" = "m" ]];then
	echo "period参数格式错误"
	exit
fi

if [ "$unit" = "d" ];then
	deleteDate=`date +%Y-%m-%d -d"-$number day"`
elif [ "$unit" = "m" ];then
	deleteDate=`date +%Y-%m-%d -d"-$number month"`
fi

tempFile=period_manage_`date +%Y%m%d%H%M%S`

psql -p $1 -U $2 $3 -o $tempFile<< EOF 
	DELETE FROM $4 WHERE $5 <= '$deleteDate';
EOF
rm -f $tempFile

