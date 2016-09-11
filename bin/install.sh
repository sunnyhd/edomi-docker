# IP-Adresse des EDOMI-Rechners
SERVERIP="172.18.0.2"

# EDOMI-Hauptpfad (NICHT ÄNDERN!)
MAIN_PATH="/usr/local/edomi"

install_timezone () {
	# Zeitzone zur Sicherheit auf GMT einstellen
	rm -f /etc/localtime
	ln -s /usr/share/zoneinfo/GMT0 /etc/localtime
}

install_config () {

	# Firewall
	cp config/config /etc/selinux/
	
	# Apache
	cp config/welcome.conf /etc/httpd/conf.d/
	cp config/httpd.conf /etc/httpd/conf/
	sed -i -e "s#===INSTALL-HTTP-ROOT===#$MAIN_PATH/www#g" /etc/httpd/conf/httpd.conf
	sed -i -e "s#===INSTALL-SERVERIP===#$SERVERIP#g" /etc/httpd/conf/httpd.conf
	
	# PHP
	cp config/php.conf /etc/httpd/conf.d/
	cp config/php.ini /etc/
	
	# mySQL
	cp config/my.cnf /etc/
	
	# FTP
	cp config/vsftpd.conf /etc/vsftpd/
	rm -f /etc/vsftpd/ftpusers
	rm -f /etc/vsftpd/user_list
}

install_mysql () {
	service mysqld start
	/usr/bin/mysqladmin -u root password ""
	mysql -e "DROP DATABASE test;"
	mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
	mysql -e "FLUSH PRIVILEGES;"
	
	# Remote-Access aktivieren (z.B. vom iMac aus)
	# mysql -e "GRANT ALL ON *.* TO mysql@'%';"
}

install_edomi () {
	service mysqld stop
	sleep 1

	if [ -f "EDOMI/EDOMI-Backup.edomibackup" ]
	then
		tar -xf EDOMI/EDOMI-Backup.edomibackup -C /
		chmod 777 -R $MAIN_PATH		
	else
		mkdir -p $MAIN_PATH
		tar -xf EDOMI/EDOMI-Public.edomiinstall -C $MAIN_PATH --strip-components=3
		chmod 777 -R $MAIN_PATH
	fi

	# edomi.ini anpassen
	sed -i -e "s#global_serverIP.*#global_serverIP='$SERVERIP'#" $MAIN_PATH/edomi.ini
	
	# Autostart: EDOMI
	echo "sh $MAIN_PATH/main/start.sh" >> /etc/rc.d/rc.local
}


install_extensions () {
	cp php/bcompiler.so /usr/lib64/php/modules/bcompiler.so
	cp php/bcompiler.ini /etc/php.d/bcompiler.ini
}


# Installationsscript

osversion="$(cat /etc/issue)"
clear
install_config
install_mysql
install_edomi
install_extensions
exit