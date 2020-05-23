%define build_day       %(date +%Y%m%d)
Name:           SCS-cerate-update-sql
Version:        1.0
Release:        1.%{build_day}%{?dist}.02
Summary:        根据需要升级的软件包名称列表，通过shell脚本生成相应更新用sql脚本。

Group:          CS2C NeoKylin Project
License:        GPL
URL:            http://www.cs2c.com.cn
Source0:        SCS-APP-All-List.txt
Source1:        createPKGsql.sh
Source2:        SCS-APP-Update-SQL-Template.sql
# update list
Source3:        UPDATELIST_mips64el.txt
Source4:        UPDATELIST_aarch64.txt
Source5:        UPDATELIST_x86_64.txt

BuildRequires:  coreutils
BuildRequires:  yum
BuildRequires:  yum-utils


%description
根据需要升级的软件包名称列表，通过shell脚本生成相应更新用sql脚本。


%prep
#%setup -q
rm -rf %{name}
mkdir -p %{name}
cp %{SOURCE0} %{name}/
cp %{SOURCE1} %{name}/
cp %{SOURCE2} %{name}/
cp %{SOURCE3} %{name}/

%build
cd %{name}
%ifarch mips64el mips64
./createPKGsql.sh UPDATELIST_mips64el.txt
%endif
%ifarch x86_64
./createPKGsql.sh UPDATELIST_x86_64.txt
%endif
%ifarch aarch64
./createPKGsql.sh UPDATELIST_aarch64.txt
%endif

%install
#make install DESTDIR=%{buildroot}
cd %{name}
mkdir -p %{buildroot}/opt/scs-app/
cp -rf %{build_day} %{buildroot}/opt/scs-app/
cp -rf %{build_day}.sql %{buildroot}/opt/scs-app/

%files
#%doc
/opt/scs-app/%{build_day}
/opt/scs-app/%{build_day}.sql


%changelog
* Wed May 20 2020 Dapeng <wukunpeng.wu@cs2c.com.cn> - 1.0-1.20200520.01
- Init.
