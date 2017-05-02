FROM centos:centos6.8
MAINTAINER Julio Cesar Arevalo <jarevalo@version3.co> 

# Varables de Entorno
ENV HOME /root
ENV ASTERISKUSER asterisk
ENV ASTERISK_DB_PW ny3ktxul
ENV AUTOBUILD_UNIXTIME 1418234402

CMD ["/sbin/my_init"]

# Agrega Volumen de backup para FREEPBX
VOLUME ["/etc/freepbxbackup"]

# Agrega script de inicio start.sh
ADD start.sh /root/
ADD upgrade_mod.sh /root/
RUN chmod +x /root/upgrade_mod.sh

# Creacion de Usuario asterisk
RUN groupadd -r $ASTERISKUSER \
  	&& useradd -r -g $ASTERISKUSER $ASTERISKUSER \
	&& usermod --home /var/lib/asterisk $ASTERISKUSER

#Actualizacion de Paquetes
RUN yum -y groupinstall core && yum -y groupinstall base

#Instala Dependencias
RUN yum install -y dnsmasq wget nano php-mbstring httpd libtermcap­audiofile­ php-process \
		&& sleep 5 \
		&& yum clean all \
		&& yum -y install php-5.3-zend-guard-loader sysadmin ImageMagick

#Instala Repo Asterisk-Now, Programa Asterisk & Freepbx
RUN rpm -ivh http://packages.asterisk.org/centos/6/current/x86_64/RPMS/asterisknow-version-3.0.1-3_centos6.noarch.rpm
RUN wget http://yum.schmoozecom.net/schmooze-commercial/schmooze-commercial.repo -O /etc/yum.repos.d/schmooze-commercial.repo
RUN yum clean all
RUN yum install -y asterisk-core asterisk-addons-mysql \
		   asterisk-configs asterisk-odbc \
		   asterisk-sounds-core-en-alaw \
		   asterisk-sounds-extra-en-alaw \
		   dahdi-linux dahdi-tools libpri dahdi* kernel-devel --enablerepo=asterisk-11

#Configurando PHP y Apache
RUN 	cp /etc/php.ini /etc/php.ini_orig \
	&& cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_orig \
	&& sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config

COPY php.ini /etc/
COPY httpd.conf /etc/httpd/conf/
	
#Configurando Permisos de Asterisk
RUN 	chown $ASTERISKUSER. /var/run/asterisk \
	&& chown -R $ASTERISKUSER. /etc/asterisk \ 
	&& chown -R $ASTERISKUSER. /var/lib/asterisk \ 
	&& chown -R $ASTERISKUSER. /var/log/asterisk \ 
	&& chown -R $ASTERISKUSER. /var/spool/asterisk \ 
	&& chown -R $ASTERISKUSER. /usr/lib64/asterisk \ 
	&& chown -R $ASTERISKUSER. /var/www/ \ 
	&& chown -R $ASTERISKUSER. /var/www/* \
	&& chown $ASTERISKUSER:$ASTERISKUSER /etc/freepbxbackup
	

#Configurando MYSQL
RUN yum install mysql-server -y && /etc/init.d/mysqld start \  
	  && mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';" \
	  && mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';" \
	  && mysql -u root -e "flush privileges;"

COPY my.cnf /etc/

#Configurando Freepbx##
RUN yum -y install freepbx --enablerepo=asterisk-current
RUN cd /usr/src/freepbx* \
	&& sleep 5 \
	&& /etc/init.d/mysqld start \
	&& /etc/init.d/httpd start \
	&& ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3 \
	&& /usr/sbin/asterisk start 1>/dev/null \
	&& ./install_amp --installdb --username=$ASTERISKUSER --password=$ASTERISK_DB_PW \
	&& sleep 5 \
	&& chown -R $ASTERISKUSER. /var/lib/asterisk/bin/retrieve_conf \
	&& chown -R $ASTERISKUSER. /etc/modprobe.d/ \
	&& chown -R $ASTERISKUSER. /var/lib/asterisk/ 

EXPOSE 3307 8081 5060-5061
EXPOSE 4569/udp 5060-5061/udp 10000-20000/udp

#Comando de inicio de servicios automaticos
CMD bash -C '/root/start.sh';'bash'

