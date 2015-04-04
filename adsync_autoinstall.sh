#!/bin/bash

echo -e "\nadsync_autoinstall.sh\nSteven CHARRIER - http://stevencharrier.fr/ - https://github.com/Punk--Rock\nVersion 1.3 - 04/04/2015\n\nInitialisation en cours...\n"
sleep 5

if [ "$USER" = "root" ]
then
	cd /opt/

	if [ -d "zimbra" ]
	then
		cd zimbra/
	else
		echo "Zimbra doit être installé pour éxecuter ce script !"
		
		exit 0
	fi

	if [ -d "adsync" ]
	then
		cd adsync/
	else
		mkdir adsync/

		cd adsync/
	fi
	
	read -p "Quel est le nom domaine sur lequel est connecté Zimbra ? [] " DOMAIN_AD
	
	echo -e "\nCréation de adsync_exec.sh...\n"

	echo "#!/bin/bash
PATH=\"/opt/zimbra/bin:/opt/zimbra/postfix/sbin:/opt/zimbra/openldap/bin:/opt/zimbra/snmp/bin:/opt/zimbra/rsync/bin:/opt/zimbra/bdb/bin:/opt/zimbra/openssl/bin:/opt/zimbra/java/bin:/usr/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games\"

DOMAIN=\"$DOMAIN_AD\"
TEMP_PATH=\"/tmp\"
ADSYNC_PATH=\"/opt/zimbra/adsync\"

cd \$TEMP_PATH

cp \$ADSYNC_PATH/Accounts.txt Accounts.txt
cp \$ADSYNC_PATH/Mails.txt Mails.txt

zmaccts | grep \"@\$DOMAIN\" | awk '{print \$1}' > ZimbraUsers.txt

sort Mails.txt > Mails2.txt
mv Mails2.txt Mails.txt
sort ZimbraUsers.txt > ZimbraUsers2.txt
mv ZimbraUsers2.txt ZimbraUsers.txt

LISTDIFF=\$(diff -u -i -B ZimbraUsers.txt Mails.txt | grep \$DOMAIN | grep \"+\" | sed s/^+//g)

echo -e \"\nSync. des comptes e-mail de \$DOMAIN en cours...\n\"

NOMBRE_COMPTES=0
for i in \$LISTDIFF; do
EMAIL=\$(echo \$i | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
FIRSTNAME=\$(cat Accounts.txt | grep \$i | cut -d ':' -f2 )
LASTNAME=\$(cat Accounts.txt | grep \$i | cut -d ':' -f1 )
echo \$FIRSTNAME \$LASTNAME \"<\"\$EMAIL\">......OK\"
zmprov ca \$EMAIL FDD00123456789 displayName ''\$FIRSTNAME' '\$LASTNAME'' givenName \$FIRSTNAME sn \$LASTNAME > /dev/null
NOMBRE_COMPTES=\$((NOMBRE_COMPTES + 1))
done

echo -e \"\n\$NOMBRE_COMPTES comptes e-mail sync.\n\"

rm -rf *.txt
rm -rf \$ADSYNC_PATH/*.txt

exit 0" > adsync_exec.sh

	chmod 755 adsync_exec.sh
	
	echo -e "Mise à jour du système (cette opération peut prendre du temps)...\n"

	echo "	apt-get update"
	
	sleep 3
	
	apt-get update > /dev/null
	
	echo "	apt-get upgrade"
	
	sleep 3
	
	apt-get -y upgrade > /dev/null

	echo "	apt-get dist-upgrade"
	
	sleep 3
	
	apt-get -y dist-upgrade > /dev/null

	echo -e "\nInstallation et paramétrage de Samba...\n"
	
	echo "	apt-get install samba"

	apt-get -y install samba > /dev/null
	
	echo "	Sauvegarde de smb.conf"

	cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
	
	echo "	Paramétrage de smb.conf"

	echo -e "[global]
        server string = $HOSTNAME
	map to guest = Bad user
	idmap config * : backend = tdb
[adsync]
        comment = adsync
        path = /opt/zimbra/adsync
        read only = No
	create mask = 0777
	directory mask = 0777
	guest ok = Yes" > /etc/samba/smb.conf

	smbd restart &&	nmbd restart

	echo -e "\nCréation de adsync_cron.sh...\n"

	touch adsync_cron.sh

	echo "#!/bin/bash
	
cd /opt/

if [ -d \"zimbra\" ]
then
	cd zimbra/
else
	exit 0
fi

if [ -d \"adsync\" ]
then
	cd adsync/
else
	exit 0
fi

if [ -f \"Accounts.txt\" ] && [ -f \"Mails.txt\" ]
then
	./adsync_exec.sh
else
	exit 0
fi" > adsync_cron.sh

	chmod 755 adsync_cron.sh

	echo -e "Ajout de adsync_cron.sh dans crontab...\n"

	su - zimbra -c "cd /tmp/;

crontab -l > crontabl;

if ! grep -q 'adsync_cron.sh' \"crontabl\";
then
	echo \"*/1 * * * * /opt/zimbra/adsync/adsync_cron.sh > /tmp/adsync_cron.log\" >> crontabl
	echo -e \"	*/1 * * * * /opt/zimbra/adsync/adsync_cron.sh > /tmp/adsync_cron.log\n\"
else
	echo -e \"	L'entrée est déjà présente dans crontab\n\"
fi;

crontab crontabl;

rm crontabl;

exit;"

	echo -e "Réglage de quelques derniers petits détails...\n"

	chown -R zimbra:zimbra /opt/zimbra/adsync/
	
	chmod 757 /opt/zimbra/adsync/
else
	echo "Vous ne disposez pas des privillèges root !"
fi
