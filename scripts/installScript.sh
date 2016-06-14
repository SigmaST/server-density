#!/bin/bash
YUM_CMD="yum -d0 -e0 -y"
EASY_INTALL_PIP="sudo easy_install pip"

#CHUSER="sh -c 'echo $USER'"

CHMOD="chmod 777 /etc/sd-agent/config.cfg"
SD_CONFIG_FILE="/etc/sd-agent/config.cfg"
KEY_DIRECTORY="/var/lib/jelastic/keys/"
SD_LOG_DIR="/var/log/sd-agent/"
SD_INSTALL_DIR="/usr/bin/sd-agent/"
MCON="yum -y install https://raw.githubusercontent.com/jelastic-jps/serverDensity/master/dumps/mysql-community-libs-compat-5.7.7-0.3.rc.el7.x86_64.rpm MySQL-python.x86_64"
MYSQL_PLUGIN_SCRIPT="curl -fsS 'https://raw.githubusercontent.com/jelastic-jps/serverDensity/master/scripts/MySQL.py' -o ${KEY_DIRECTORY}/MySQL.py"
MONGO_PLUGIN_SCRIPT="pip install pymongo && curl -fsS 'https://raw.githubusercontent.com/jelastic-jps/serverDensity/master/scripts/Mongodb.py' -o ${KEY_DIRECTORY}/Mongodb.py"
PASSWORD=$(cat /var/log/jem.log  | grep passwd | tail -n 1 | awk -F "-p " '{ print $2}');
IGNORE_RELEASE=0
 
while getopts ":a:k:g:t:T:" opt; do
  case $opt in
    a)
      ACCOUNT="$OPTARG" >&2
      ;;
    k)
      AGENTKEY="$OPTARG" >&2
      ;;
    g)
      GROUPNAME="$OPTARG" >&2
      ;;
    t)
      API_KEY="$OPTARG" >&2
      ;;
    T)
      TAGNAME="$OPTARG" >&2
      ;;
    \?)
      exit
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      #exit 1
      ;;
  esac
done
sudo sh -c "cat - > /etc/yum.repos.d/serverdensity.repo <<EOF
[serverdensity]
name=Server Density
baseurl=http://www.serverdensity.com/downloads/linux/redhat/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-serverdensity
EOF"
rpm --import https://www.serverdensity.com/downloads/boxedice-public.key
if [ $? -gt 0 ]; then
echo "Error downloading key"
exit 1
fi
echo "Installing agent"
${YUM_CMD} install sd-agent python-devel sysstat python-setuptools python-setuptools-devel
${EASY_INTALL_PIP}
if [ "${HOSTNAME}" = "" ]; then
echo "Host does not appear to have a hostname set!"
exit 1
fi
if [ "${TAGNAME}" != "" ]; then
 
        TAGS=`curl --silent -X GET https://api.serverdensity.io/inventory/tags?token=${API_KEY}`
 
        # very messy way to get the tag ID without using any json tools
        TAGID=`echo $TAGS | sed -e $'s/},{/\\\n/g'| grep -i "\"$TAGNAME"\" | sed 's/.*"_id":"\([a-z0-9]*\)".*/\1/g'` 
 
        if [ ! -z $TAGID ]; then
            echo "Found $TAGNAME, using tag ID $TAGID"
 
        else
 
            MD5=`which md5`
            if [ -z $MD5 ]; then
                MD5=`which md5sum`
            fi
            HEX="#`echo -n $TAGNAME | $MD5 | cut -c1-6`"
 
            echo "Creating tag $TAGNAME with random hex code $HEX"
            TAGS=`curl --silent -X POST https://api.serverdensity.io/inventory/tags?token=${API_KEY} --data "name=$TAGNAME&color=$HEX"`
 
            TAGID=`echo $TAGS | grep -i $TAGNAME | sed 's/.*"_id":"\([a-z0-9]*\)".*/\1/g'`
            echo "Tag cretated, using tag ID $TAGID"
 
        fi
 
        if [ "${GROUPNAME}" = "" ]; then
            RESULT=`curl -v https://api.serverdensity.io/inventory/devices/?token=${API_KEY} --data "name=${HOSTNAME}&tags=[\"$TAGID\"]"`
        fi
 
        if [ "${GROUPNAME}" != "" ]; then
            RESULT=`curl -v https://api.serverdensity.io/inventory/devices/?token=${API_KEY} --data "group=${GROUPNAME}&name=${HOSTNAME}&tags=[\"$TAGID\"]"`
        fi
 
    else
 
        if [ "${GROUPNAME}" = "" ]; then
            RESULT=`curl -v https://api.serverdensity.io/inventory/devices/?token=${API_KEY} --data "name=${HOSTNAME}"`
        fi
 
        if [ "${GROUPNAME}" != "" ]; then
            RESULT=`curl -v https://api.serverdensity.io/inventory/devices/?token=${API_KEY} --data "group=${GROUPNAME}&name=${HOSTNAME}"`
        fi
 
    fi
AGENTKEY=`echo $RESULT | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w agentKey | cut -d"|" -f2| sed -e 's/^ *//g' -e 's/ *$//g'`
 
source /etc/jelastic/metainf.conf
 
PLUGIN=`grep $COMPUTE_TYPE /etc/jelastic/extendperm.conf  | awk '{print $2}' | sed 's/\;/\n/g' | grep conf.d`
sh -c "cat - > /etc/sd-agent/config.cfg <<EOF
[Main]
sd_url: $ACCOUNT
agent_key: $AGENTKEY
#
# Plugins
#
# Leave blank to ignore. See http://www.serverdensity.com/docs/agent/writingplugins/
#
  
plugin_directory: ${KEY_DIRECTORY}
  
#
# Optional status monitoring
#
# See http://www.serverdensity.com/docs/agent/config/
# Ignore these if you do not wish to monitor them
#
  
# Apache
# See http://www.serverdensity.com/docs/agent/apache/
 
# apache_status_url: http://www.example.com/server-status/?auto
# apache_status_user:
# apache_status_pass:
 
[MongoDB]
mongodb_plugin_server: admin:${PASSWORD}@127.0.0.1:27017
mongodb_plugin_dbstats: yes
mongodb_plugin_replset: no
 
[MySQLServer]
mysql_server: localhost
mysql_user: root
mysql_pass: ${PASSWORD}
 
# nginx
# See http://www.serverdensity.com/docs/agent/nginx/
 
# nginx_status_url: http://www.example.com/nginx_status
 
# RabbitMQ
# See http://www.serverdensity.com/docs/agent/rabbitmq/
 
# for rabbit > 2.x use this url:
# rabbitmq_status_url: http://www.example.com:55672/api/overview
# for earlier, use this:
# rabbitmq_status_url: http://www.example.com:55672/json
# rabbitmq_user: guest
# rabbitmq_pass: guest
 
# Temporary file location
# See http://www.serverdensity.com/docs/agent/config/
 
# tmp_directory:
 
# Pid file location
# See http://www.serverdensity.com/docs/agent/config/
 
# pidfile_directory:
 
# Set log level
# See http://www.serverdensity.com/docs/agent/config/
 
logging_level: debug
[Memcached]
host = '127.0.0.1'
port = 11211
EOF"
sh -c "usermod -a -G ssh-access sd-agent && sudo /etc/init.d/sd-agent restart"
TYPE=`echo $COMPUTE_TYPE`
if [ "${TYPE}" = "apache-php" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R apache:apache ${KEY_DIRECTORY} && chown -R chown -R sd-agent:sd-agent ${SD_INSTALL_DIR} && chown -R apache:apache ${SD_LOG_DIR}"
fi
if [ "${TYPE}" = "nginx-php" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R nginx:nginx ${KEY_DIRECTORY} && chown nginx:nginx ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "balancer" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R nginx:nginx ${KEY_DIRECTORY} && chown nginx:nginx ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "couchdb" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R nginx:nginx ${KEY_DIRECTORY} && chown couchdb:couchdb ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "mysql" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R 777 /var/lib/jelastic/keys/config.cfg && chmod 666 /etc/sd-agent/config.cfg && $MCON && $MYSQL_PLUGIN_SCRIPT"
fi
if [ "${TYPE}" = "memcached" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown 777 ${KEY_DIRECTORY} && cd /var/lib/jelastic/keys &&  curl -fsS 'https://raw.githubusercontent.com/jelastic-jps/serverDensity/master/scripts/Memcached.py' -o Memcached.py"
fi
if [ "${TYPE}" = "mongodb" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R mongod:mongod ${KEY_DIRECTORY} && ${CHMOD} && ${MONGO_PLUGIN_SCRIPT}"
fi
if [ "${TYPE}" = "postgres" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R postgres:postgres ${KEY_DIRECTORY} && chown postgres:postgres ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "mariadb" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R mysql:mysql ${KEY_DIRECTORY} && chown mysql:mysql ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "cartridge" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} /opt/shared/keys/ && ln -s ${SD_LOG_DIR} /opt/shared/keys/ && chown -R jelastic:jelastic /opt/shared/keys/ && chown jelastic:jelastic ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "Percona" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic:jelastic ${KEY_DIRECTORY} && chown jelastic:jelastic ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "tomcat" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic ${KEY_DIRECTORY} && chmod 666 ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "glassfish" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic ${KEY_DIRECTORY} && chmod 666 ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "jetty" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic ${KEY_DIRECTORY} && chmod 666 ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "tomee" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic ${KEY_DIRECTORY} && chmod 666 ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "apache-ruby" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic ${KEY_DIRECTORY} && chmod 666 ${SD_CONFIG_FILE}"
fi
if [ "${TYPE}" = "nginx-ruby" ]; then
     sh -c "ln -s ${SD_CONFIG_FILE} ${KEY_DIRECTORY} && ln -s ${SD_LOG_DIR} ${KEY_DIRECTORY} && chown -R jelastic ${KEY_DIRECTORY} && chmod 666 ${SD_CONFIG_FILE}"
fi
/etc/init.d/sd-agent restart