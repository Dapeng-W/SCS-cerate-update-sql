#!/bin/bash
# Maintainer : Dapeng
# Init at    : 2020-05-19
# Maintainer :
# Modify at  :

#DATE=`date +%Y-%m-%d_%H-%M-%S`
DATE=`date +%Y%m%d`

if [ ! -n "$1" ]; then
    echo ""
    echo "Usage..."
    echo ""
    echo "    ./createPKGsql.sh UPDATELIST_FILE"
    echo ""
    echo "eg :"
    echo "    ./createPKGsql.sh UPDATELIST_mips64el.txt"
    echo ""
    exit
fi

# UPDATELIST_FILE 是 软件中心服务端(SCS) 需要进行升级的应用软件包名的列表文件
# 	如何生成 UPDATELIST_FILE (TODO):
# 		被配置为连接服务端 update.cs2c.com.cn 的 软件中心客户端(SCC) 成功运行起来之后, 本地存在 sqlite 文件 : /opt/softwarecenter/db/software.db
# 		1, 运行shell命令 `sqlite3 /opt/softwarecenter/db/software.db -line 'select s_rpm from softwares;' |awk '{print $3}' > all-origin-app-list.txt` 以导出 software.db 中带版本号的软件列表到临时文件 all-origin-app-list.txt 中, 并通过执行 `sed -i '/^$/d' all-origin-app-list.txt` 来删除其中的空行, 再通过执行 `sed -i ':label;N;s/\n/ /;b label' all-origin-app-list.txt` 将其中的换行附替换成空格;
# 		2, 将 SCC 所有的 yum repo 禁用, 启用 baseurl 指向 koji 仓库的 yum repo, 之后 shell 运行 `yum clean all`;
# 		3, shell 运行 yum install `cat all-origin-app-list.txt` --installroot=<tmprootfsdir> , 其中 <tmprootfsdir> 是一个临时创建的空目录, 该命令运行时不需要真的确认安装，会有提示说部分 PACKAGES "没有可用软件包",  而这些些 yum 找不到的包，一部分是因为第三方软件不在 koji 仓库里, 另一部分是因为版本不匹配 koji 仓库里存在的最新版本. 而这些因版本不匹配而找不到的包正是我们需要对其进行更新的,  最后 手动(FIXME) 将不匹配的 PACKAGES 的不带版本号的包名写入 UPDATELIST_FILE 文件中.
# 	UPDATELIST_FILE 文件名称 :
#		mips64el : UPDATELIST_mips64el.txt
# 		x86_64   : UPDATELIST_x86_64.txt
# 		aarch64  : UPDATELIST_aarch64.txt
UPDATELIST_FILE=$1
echo "[INFO] Reading application packages from : $UPDATELIST_FILE"

echo "USE software_center;" > $DATE.sql

while read PKGNAME
do
	# echo -e "[INFO] PKGNAME       : \033[33m$PKGNAME\033[0m"
	echo "[INFO] PKGNAME       : $PKGNAME"

	# SCS 所有应用软件包名称列表, (TODO)应保持三个名台同样的包名都对应一样的软件名称, 且当 SCS 发生软件包名称信息变化时应及时更新 appnamelist.txt
	APP_LIST_FILE='SCS-APP-All-List.txt'
	# 惯用 mysql 语句模板
	SQL_TEMPLATE='SCS-APP-Update-SQL-Template.sql'

	# for download $PKGNAME in a temporary directory
	TMPDIR=$(mktemp -d)
	echo "[INFO] TemporaryDir  : $TMPDIR"
	yumdownloader --destdir $TMPDIR $PKGNAME

	FILE_NAME=$(ls -l $TMPDIR |awk '{print $9}')
	FILE_SIZE=$(ls -l $TMPDIR |awk '{print $5}')
	echo "[INFO] FILENAME      : $FILE_NAME"
	echo "[INFO] FILESIZE      : $FILE_SIZE"

	# NAME=$(rpm -qpi $TMPDIR/*rpm |grep "Name" |grep ":" |awk '{print $3}')
	APPNAME=$(cat $APP_LIST_FILE |grep "$PKGNAME" |awk '{print $2,$3,$4}')
	VERSION=$(rpm -qpi $TMPDIR/*rpm |grep "Version" |grep ":" |awk '{print $3}')
	RELEASE=$(rpm -qpi $TMPDIR/*rpm |grep "Release" |grep ":" |awk '{print $3}')
	APPARCH=$(rpm -qpi $TMPDIR/*rpm |grep "Architecture" |grep ":" |awk '{print $2}')
	echo "[INFO] 软件名称      : $APPNAME"
	echo "[INFO] 软件版本      : $VERSION"
	echo "[INFO] 软件release号 : $RELEASE"
	echo "[INFO] 软件架构      : $APPARCH"

	mkdir -p $DATE/$APPARCH/
	# mkdir -p $APPARCH/$PKGNAME-$VERSION-$RELEASE
	script=$DATE/$APPARCH/$PKGNAME-$VERSION-$RELEASE.sql
	# script=$APPARCH/$PKGNAME-$VERSION-$RELEASE/$PKGNAME-$VERSION-$RELEASE.sql

	# cp -f SCS-APP-Update-SQL-Template.sql $PKGNAME-$VERSION-$RELEASE/$PKGNAME.sql
	cp -vf $SQL_TEMPLATE $script

	sed -i "s/testsize/$(echo $FILE_SIZE)/" $script
	sed -i "s/testversion/$(echo $VERSION-$RELEASE)/" $script
	sed -i "s/testname/$(echo $PKGNAME-$VERSION-$RELEASE)/" $script
	sed -i "s/appname/$(echo $APPNAME)/" $script
	cat $script >> $DATE.sql
	# (TODO) $DATE.sql 应该经过检查再使用
	cat $script
	rm -rf $TMPDIR
	echo
done < $UPDATELIST_FILE
