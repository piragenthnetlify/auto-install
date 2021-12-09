#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

KASM_VERSION="1.10.0"
KASM_INSTALL_BASE="/opt/kasm/${KASM_VERSION}"
DO_DATABASE_INIT='true'
VERBOSE='false'
ACCEPT_EULA='false'
API_INSTALL='false'
PUBLIC_HOSTNAME='false'
DEFAULT_PROXY_LISTENING_PORT='443'
DATABASE_HOSTNAME='false'
DATABASE_PORT=5432
DATABASE_SSL='true'
REDIS_HOSTNAME='false'
MANAGER_HOSTNAME='false'
API_SERVER_HOSTNAME='false'
SERVER_ZONE='default'
SERVER_ID='false'
PROVIDER='false'
bflag=''
files=''
START_SERVICES='true'
DEFAULT_ADMIN_PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 )"
DEFAULT_USER_PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 )"
DEFAULT_DATABASE_PASSWORD="false"
DEFAULT_REDIS_PASSWORD="false"
DEFAULT_MANAGER_TOKEN="false"
ROLE="all"
OFFLINE_INSTALL="false"
PULL_IMAGES="true"
SEED_IMAGES="true"

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
KASM_RELEASE="$(realpath $SCRIPT_PATH)"
EULA_PATH=${KASM_RELEASE}/licenses/LICENSE.txt
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')


function is_port_ok (){


    re='^[0-9]+$'
    if ! [[ ${DEFAULT_PROXY_LISTENING_PORT} =~ $re ]] ; then
       echo "error: DEFAULT_PROXY_LISTENING_PORT, (${DEFAULT_PROXY_LISTENING_PORT}) is not an integer" >&2; exit 1
    fi

    if ((${DEFAULT_PROXY_LISTENING_PORT} <= 0 || ${DEFAULT_PROXY_LISTENING_PORT} > 65535 )); then
      echo "error: DEFAULT_PROXY_LISTENING_PORT, (${DEFAULT_PROXY_LISTENING_PORT}) is in the valid port range"
      exit 1
    fi

    echo "Checking if DEFAULT_PROXY_LISTENING_PORT (${DEFAULT_PROXY_LISTENING_PORT}) is free"
    if lsof -Pi :${DEFAULT_PROXY_LISTENING_PORT} -sTCP:LISTEN  ; then
        echo "Port (${DEFAULT_PROXY_LISTENING_PORT}) is in use. Installation cannot continue."
        exit -1
    else
        echo "Port (${DEFAULT_PROXY_LISTENING_PORT}) is not in use."
    fi
}

function set_listening_port(){

    if [ "${DEFAULT_PROXY_LISTENING_PORT}" != "443" ] ;
    then
        echo "Updating configurations with custom DEFAULT_PROXY_LISTENING_PORT (${DEFAULT_PROXY_LISTENING_PORT})"

        FILE=${KASM_INSTALL_BASE}/conf/database/seed_data/default_properties.yaml
        if [ -f "${FILE}" ]; then
            sed -i "s/proxy_port:.*/proxy_port: ${DEFAULT_PROXY_LISTENING_PORT}/g" ${FILE}
        fi

        FILE=${KASM_INSTALL_BASE}/conf/app/agent.app.config.yaml
        if [ -f "${FILE}" ]; then
            sed -i "s/public_port.*/public_port: ${DEFAULT_PROXY_LISTENING_PORT}/g" ${FILE}
        fi

        FILE=${KASM_INSTALL_BASE}/conf/nginx/orchestrator.conf
        if [ -f "${FILE}" ]; then
            sed -i "s/listen.*/listen ${DEFAULT_PROXY_LISTENING_PORT} ssl ;/g" ${FILE}
        fi

        grep -rl "443:443" ${KASM_INSTALL_BASE}/docker/ | xargs -I '{}' sed -i "s/- \"443:443\"/- \"${DEFAULT_PROXY_LISTENING_PORT}:${DEFAULT_PROXY_LISTENING_PORT}\"/g" {}

    fi

}

function get_public_hostname (){

    if [ "${PUBLIC_HOSTNAME}" == "false" ] ;
    then
       _PUBLIC_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
        read -p "Enter the network facing IP or hostname [${_PUBLIC_IP}]: " public_hostname_input
        if [ "${public_hostname_input}" == "" ] ;
        then
            PUBLIC_HOSTNAME=${_PUBLIC_IP}
        else
            PUBLIC_HOSTNAME=${public_hostname_input}
        fi
        echo "Using ip/hostname: [${PUBLIC_HOSTNAME}]"
    fi

}

function get_database_hostname (){

    if [ "${DATABASE_HOSTNAME}" == "false" ] ;
    then
        database_hostname_input=
        while [[ $database_hostname_input = "" ]]; do
            read -p "Enter the Kasm Database's hostname or IP : " database_hostname_input
        done

        DATABASE_HOSTNAME=${database_hostname_input}
        echo "Using database ip/hostname: [${DATABASE_HOSTNAME}]"
    fi

}

function set_random_database_password (){
    # Honor the default if its passed in
    if [ "${DEFAULT_DATABASE_PASSWORD}" == "false" ] ;
    then
        DEFAULT_DATABASE_PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 )"
    fi

}

function set_random_redis_password (){
    # Honor the default if its passed in
    if [ "${DEFAULT_REDIS_PASSWORD}" == "false" ] ;
    then
        DEFAULT_REDIS_PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 )"
    fi

}

function set_random_manager_token (){
    # Honor the default if its passed in
    if [ "${DEFAULT_MANAGER_TOKEN}" == "false" ] ;
    then
        DEFAULT_MANAGER_TOKEN="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20 )"
    fi

}

function get_database_password (){

    if [ "${DEFAULT_DATABASE_PASSWORD}" == "false" ] ;
    then
        database_password_input=
        while [[ $database_password_input = "" ]]; do
            read -p "Enter the Kasm Database's password : " database_password_input
        done

        DEFAULT_DATABASE_PASSWORD=${database_password_input}
        echo "Using database password: [${DEFAULT_DATABASE_PASSWORD}]"
    fi

}

function get_redis_password (){

    if [ "${DEFAULT_REDIS_PASSWORD}" == "false" ] ;
    then
        redis_password_input=
        while [[ $redis_password_input = "" ]]; do
            read -p "Enter the Kasm Redis'password : " redis_password_input
        done

        DEFAULT_REDIS_PASSWORD=${redis_password_input}
        echo "Using redis password: [${DEFAULT_REDIS_PASSWORD}]"
    fi

}

function get_manager_hostname (){

    if [ "${MANAGER_HOSTNAME}" == "false" ] ;
    then
        manager_hostname_input=
        while [[ $manager_hostname_input = "" ]]; do
            read -p "Enter the Kasm manager's hostname or IP : " manager_hostname_input
        done

        MANAGER_HOSTNAME=${manager_hostname_input}
        echo "Using manager ip/hostname: [${MANAGER_HOSTNAME}]"
    fi

}

function get_manager_token (){

    if [ "${DEFUALT_MANAGER_TOKEN}" == "false" ] ;
    then
        manager_token_input=
        while [[ $manager_token_input = "" ]]; do
            read -p "Enter the Kasm manager's hostname or IP : " manager_token_input
        done

        DEFUALT_MANAGER_TOKEN=${manager_token_input}
        echo "Using manager token: [${DEFUALT_MANAGER_TOKEN}]"
    fi

}

function set_public_hostname() {
    sed -i "s/public_hostname.*/public_hostname: ${PUBLIC_HOSTNAME}/g" ${KASM_INSTALL_BASE}/conf/app/agent.app.config.yaml
}

function set_default_user_passwords() {
    sed -i "s/password: admin.*/password: \"${DEFAULT_ADMIN_PASSWORD}\"/g" ${KASM_INSTALL_BASE}/conf/database/seed_data/default_properties.yaml
    sed -i "s/password: user.*/password: \"${DEFAULT_USER_PASSWORD}\"/g" ${KASM_INSTALL_BASE}/conf/database/seed_data/default_properties.yaml
}

function set_database_hostname() {
	if [ "${DATABASE_HOSTNAME}" != "false" ] ;
	then
        sed -i "s/host: db/host: ${DATABASE_HOSTNAME}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
    fi
}

function set_database_port() {
	sed -i "s/port: 5432/port: ${DATABASE_PORT}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
}

function set_database_password() {
    sed -i "s/ password:.*/ password: \"${DEFAULT_DATABASE_PASSWORD}\"/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
    grep -rl POSTGRES_PASSWORD ${KASM_INSTALL_BASE}/docker/ | xargs -I '{}' sed -i "s/POSTGRES_PASSWORD:.*/POSTGRES_PASSWORD: \"${DEFAULT_DATABASE_PASSWORD}\"/g" {}
}

function set_database_ssl() {
	if [ "${DATABASE_SSL}" == "false" ] ; then
	    sed -i 's/ssl: true/ssl: false/' ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
	    sed -i 's# -c ssl=on -c ssl_cert_file=/etc/ssl/certs/db_server.crt -c ssl_key_file=/etc/ssl/certs/db_server.key##' ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
    fi
    # if local db then generate certs
    if [ "${DATABASE_HOSTNAME}" == "false" ] ; then
    	sudo openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout ${KASM_INSTALL_BASE}/certs/db_server.key -out ${KASM_INSTALL_BASE}/certs/db_server.crt -subj "/C=US/ST=VA/L=None/O=None/OU=DoFu/CN=$(hostname)/emailAddress=none@none.none" 2> /dev/null
        # If there is no user with UID of 70 and no kasm_db user, we create kasm_db with UID of 70
        if ! id -nu 70 > /dev/null 2>&1; then
		    if ! grep -q '^kasm_db:' /etc/passwd ; then
			    sudo useradd -u 70 kasm_db
            fi
		fi
		sudo chown 70:70 ${KASM_INSTALL_BASE}/certs/db_server.key
        sudo chown 70:70 ${KASM_INSTALL_BASE}/certs/db_server.crt
        sudo chmod 0600 ${KASM_INSTALL_BASE}/certs/db_server.crt
        sudo chmod 0600 ${KASM_INSTALL_BASE}/certs/db_server.key
    fi
}

function set_redis_hostname() {
	if [ "${REDIS_HOSTNAME}" != "false" ] ;
	then
        sed -i "s/host: kasm_redis/host: ${REDIS_HOSTNAME}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
    elif [ "${DATABASE_HOSTNAME}" != "false" ] ;
	then
        sed -i "s/host: kasm_redis/host: ${DATABASE_HOSTNAME}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
    fi
}

function set_redis_password() {
    sed -i "s/redis_password:.*/redis_password: \"${DEFAULT_REDIS_PASSWORD}\"/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
    grep -rl POSTGRES_PASSWORD ${KASM_INSTALL_BASE}/docker/ | xargs -I '{}' sed -i "s/REDIS_PASSWORD:.*/REDIS_PASSWORD: \"${DEFAULT_REDIS_PASSWORD}\"/g" {}
}

function set_manager_hostname() {
    sed -i "s/hostnames: \['proxy.*/hostnames: \['${MANAGER_HOSTNAME}'\]/g" ${KASM_INSTALL_BASE}/conf/app/agent.app.config.yaml
}

function set_manager_token() {
    sed -i "s/ token:.*/ token: \"${DEFAULT_MANAGER_TOKEN}\"/g" ${KASM_INSTALL_BASE}/conf/app/agent.app.config.yaml
    FILE=${KASM_INSTALL_BASE}/conf/database/seed_data/default_properties.yaml
    if [ -f "${FILE}" ]; then
        sed -i "s/default-manager-token/${DEFAULT_MANAGER_TOKEN}/g" ${FILE}
    fi
}

function set_agent_server_id() {
    if [ "${SERVER_ID}" == "false" ] ;
    then
        SERVER_ID=$(cat /proc/sys/kernel/random/uuid)
    fi
    sed -i "s/server_id.*/server_id: ${SERVER_ID}/g" ${KASM_INSTALL_BASE}/conf/app/agent.app.config.yaml
    sed -i "s/00000000-0000-0000-0000-000000000000/${SERVER_ID}/g" ${KASM_INSTALL_BASE}/conf/database/seed_data/default_agents.yaml 
}

function set_server_zone() {
    sed -i "s/zone_name.*/zone_name: ${SERVER_ZONE}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
}

function set_api_server_id() {
    API_SERVER_ID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/server_id.*/server_id: ${API_SERVER_ID}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
}

function set_manager_id() {
    MANAGER_ID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/manager_id.*/manager_id: ${MANAGER_ID}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
}

function set_share_id() {
    SHARE_ID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/share_id.*/share_id: ${SHARE_ID}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
}

function set_api_hostname() {
    if [ "${API_SERVER_HOSTNAME}" == "false" ] ;
    then
        API_SERVER_HOSTNAME=$(hostname)
    fi
    sed -i "s/server_hostname.*/server_hostname: ${API_SERVER_HOSTNAME}/g" ${KASM_INSTALL_BASE}/conf/app/api.app.config.yaml
}

function set_provider() {
    if [ "${PROVIDER}" != "false" ] ;
    then
        sed -i "s/provider.*/provider: ${PROVIDER}/g" ${KASM_INSTALL_BASE}/conf/app/agent.app.config.yaml
    fi
}

function copy_db_config() {
    cp ${KASM_RELEASE}/conf/database/pg_hba.conf ${KASM_INSTALL_BASE}/conf/database/
    cp ${KASM_RELEASE}/conf/database/postgresql.conf ${KASM_INSTALL_BASE}/conf/database/
    chmod 600 ${KASM_INSTALL_BASE}/conf/database/pg_hba.conf ${KASM_INSTALL_BASE}/conf/database/postgresql.conf

    mkdir -p ${KASM_INSTALL_BASE}/log/postgres/
}

function base_install() {
    chmod +x ${KASM_INSTALL_BASE}/bin/*
    chmod +x ${KASM_INSTALL_BASE}/bin/utils/*
    chown kasm:kasm -R ${KASM_INSTALL_BASE}
    if [ -f ${KASM_INSTALL_BASE}/conf/database/pg_hba.conf ]; then 
    	chown 70:70 ${KASM_INSTALL_BASE}/conf/database/pg_hba.conf
    fi
    if [ -f ${KASM_INSTALL_BASE}/conf/database/postgresql.conf ]; then 
    	chown 70:70 ${KASM_INSTALL_BASE}/conf/database/postgresql.conf
    fi
    if [ -d ${KASM_INSTALL_BASE}/log/postgres/ ]; then 
    	chown -R 70:70 ${KASM_INSTALL_BASE}/log/postgres/
    fi
    if [ -f ${KASM_INSTALL_BASE}/certs/db_server.key ]; then 
    	chown 70:70 ${KASM_INSTALL_BASE}/certs/db_server.key
    fi
    if [ -f ${KASM_INSTALL_BASE}/certs/db_server.crt ]; then 
    	chown 70:70 ${KASM_INSTALL_BASE}/certs/db_server.crt
    fi
    if [ -d "${KASM_RELEASE}/www/" ]; then
      cp -r ${KASM_RELEASE}/www/ ${KASM_INSTALL_BASE}/
      chmod -R 555 ${KASM_INSTALL_BASE}/www
    fi

    if [ "${DO_DATABASE_INIT}" == "true" ] ;
    then
        echo "Initializing Database"
        set_default_user_passwords
        ${KASM_INSTALL_BASE}/bin//utils/db_init -i -s ${KASM_INSTALL_BASE}/conf/database/seed_data/default_properties.yaml -q ${DATABASE_HOSTNAME} -T ${DATABASE_PORT} -Q ${DEFAULT_DATABASE_PASSWORD} -t ${DATABASE_SSL}

        if [ "${SEED_IMAGES}" == "true" ]  ;
        then
            # If the user passes the path to the workspace images offline tarfile
            # we want to use the seedfile in there to seed the default images.
            if [ ! -z "${WORKSPACE_IMAGE_TARFILE}" ]; then
                tar xf "${WORKSPACE_IMAGE_TARFILE}" -C ${KASM_RELEASE} workspace_images/default_images_${ARCH}.yaml
                ${KASM_INSTALL_BASE}/bin//utils/db_init -s ${KASM_RELEASE}/workspace_images/default_images_${ARCH}.yaml -q ${DATABASE_HOSTNAME} -T ${DATABASE_PORT} -Q ${DEFAULT_DATABASE_PASSWORD} -t ${DATABASE_SSL}
            # We want to do nothing if the user passes in -s but not -w.
            elif [ "${OFFLINE_INSTALL}" == 'false' ]; then
                ${KASM_INSTALL_BASE}/bin//utils/db_init -s ${KASM_INSTALL_BASE}/conf/database/seed_data/default_images_${ARCH}.yaml -q ${DATABASE_HOSTNAME} -T ${DATABASE_PORT} -Q ${DEFAULT_DATABASE_PASSWORD} -t ${DATABASE_SSL}
            fi
        else
            echo "Not seeding default Workspaces Images."
        fi

        if [ "${ROLE}" == "all" ] ;
        then
            ${KASM_INSTALL_BASE}/bin//utils/db_init -s ${KASM_INSTALL_BASE}/conf/database/seed_data/default_agents.yaml -q ${DATABASE_HOSTNAME} -T ${DATABASE_PORT} -Q ${DEFAULT_DATABASE_PASSWORD} -t ${DATABASE_SSL}
        fi
        rm ${KASM_INSTALL_BASE}/conf/database/seed_data/default_properties.yaml
    fi
}

function pull_images() {
    if [ ${OFFLINE_INSTALL} == "false" ] ; then
        echo "Pulling default Workspaces Images"
        sudo docker exec kasm_db psql -U kasmapp -d kasm -t  -c "SELECT name FROM images WHERE enabled = true;" | xargs -L 1 sudo  docker pull
    fi
}

function copy_manager_configs() {
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_manager.conf  ${KASM_INSTALL_BASE}/conf/nginx/upstream_manager.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/manager_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/manager_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_api.conf ${KASM_INSTALL_BASE}/conf/nginx/upstream_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/client_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/client_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/website.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/website.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/upstream_proxy.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/upstream_proxy.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/share_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/share_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_share.conf ${KASM_INSTALL_BASE}/conf/nginx/upstream_share.conf
}

function copy_api_configs() {
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_api.conf ${KASM_INSTALL_BASE}/conf/nginx/upstream_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/admin_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/admin_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/client_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/client_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/subscription_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/subscription_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/upstream_proxy.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/upstream_proxy.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/website.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/website.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/share_api.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/share_api.conf
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_share.conf ${KASM_INSTALL_BASE}/conf/nginx/upstream_share.conf
}


function create_docker_network() {
    kasm_network=kasm_default_network
    set +e
    sudo docker network inspect ${kasm_network} &> /dev/null
    ret=$?
    set -e
    if [ $ret -ne 0 ]; then
        echo "Creating docker network ${kasm_network}"
        sudo docker network create --driver=bridge kasm_default_network
    else
        echo "Docker network ${kasm_network} already exists. Will not create"
    fi
}


function accept_eula() {
    printf "\n\n"
    echo "End User License Agreement"
    echo "__________________________"
    printf "\n\n"
    cat ${EULA_PATH}
    printf "\n\n"
    echo "A copy of the End User License Agreement is located at:"
    echo "${EULA_PATH}"
    printf "\n"
    read -p "I have read and accept End User License Agreement (y/n)? " choice
    case "$choice" in
      y|Y )
        ACCEPT_EULA="true"
        ;;
      n|N )
        echo "Installation cannot continue"
        exit 1
        ;;
      * )
        echo "Invalid Response"
        echo "Installation cannot continue"
        exit 1
        ;;
    esac

}

function check_role() {

if [ "${ROLE}" != "all" ] &&  [ "${ROLE}" != "agent" ]  &&  [ "${ROLE}" !=  "app" ] &&  [ "${ROLE}" != "db" ] ;
then
    echo "Invalid Role Defined"
    display_help
    exit 1
fi
}

function display_help() {
   echo "Usage: ${0}"
   echo "-h Display this help menu"
   echo "-v Verbose output"
   echo "-e Accept End User License Agreement"
   echo "-S Role service to install: [all | app | db | agent ]"
   echo "-p Agent <IP/Hostname>"
   echo "-d Skip database initialization"
   echo "-D Don't start services at the end of installation"
   echo "-m Manager IP/Hostname"
   echo "-U Default User Password"
   echo "-P Default Admin Password"
   echo "-L Default Proxy Listening Port"
   echo "-z Server Zone"
   echo "-o Redis Hostname"
   echo "-R Redis Password"
   echo "-q Database Hostname"
   echo "-Q Default Database Password"
   echo "-t Database, Disable SSL"
   echo "-T Database port (default 5432)"
   echo "-M Manager Token"
   echo "-I Don't seed or pull default Workspaces Images"
   echo "-u Don't pull default Workspaces Images"
   echo "-w Set the path to the tar.gz file containing workspace images offline installer"
   echo "-s Set the path to the tar.gz file containing service images offline installer"
}

function load_workspace_images () {
    if [ -z "$WORKSPACE_IMAGE_TARFILE" ]; then
        return
    fi 

    tar xf "${WORKSPACE_IMAGE_TARFILE}" -C "${KASM_RELEASE}"

    # install all kasm infrastructure images
    while IFS="" read -r image || [ -n "$image" ]; do
            echo "Loading image: $image"
            IMAGE_FILENAME=$(echo $image | sed -r 's#[:/]#_#g')
        docker load --input ${KASM_RELEASE}/workspace_images/${IMAGE_FILENAME}.tar
    done < ${KASM_RELEASE}/workspace_images/images.txt
}

function load_service_images () {
    if [ -z "$SERVICE_IMAGE_TARFILE" ]; then
        return
    fi

    tar xf "${SERVICE_IMAGE_TARFILE}" -C "${KASM_RELEASE}"

    # install all kasm infrastructure images
    while IFS="" read -r image || [ -n "$image" ]; do
            echo "Loading image: $image"
            IMAGE_FILENAME=$(echo $image | sed -r 's#[:/]#_#g')
        docker load --input ${KASM_RELEASE}/service_images/${IMAGE_FILENAME}.tar
    done < ${KASM_RELEASE}/service_images/images.txt
}

while getopts 'etdhvDIup:P:q:m:n:i:r:U:Q:L:z:R:S:t:T:o:M:w:s:' flag; do
  case "${flag}" in
    e)
        ACCEPT_EULA='true'
        ;;
    d)
        DO_DATABASE_INIT='false'
        ;;
    h)
        display_help
        exit 0
        ;;
    i)
        SERVER_ID=$OPTARG
        echo "Setting Agent Server ID as ${SERVER_ID}"
        ;;
    p)
        PUBLIC_HOSTNAME=$OPTARG
        echo "Setting Public Hostname as ${PUBLIC_HOSTNAME}"
        ;;
    P)
        DEFAULT_ADMIN_PASSWORD=$OPTARG
        echo "Setting Default Admin Password as ${DEFAULT_ADMIN_PASSWORD}"
        ;;
    L)
        DEFAULT_PROXY_LISTENING_PORT=$OPTARG
        echo "Setting Default Listening Port as ${DEFAULT_PROXY_LISTENING_PORT}"
        ;;
    U)
        DEFAULT_USER_PASSWORD=$OPTARG
        echo "Setting Default User Password as ${DEFAULT_USER_PASSWORD}"
        ;;
    Q)
        DEFAULT_DATABASE_PASSWORD=$OPTARG
        echo "Setting Default Database Password as ${DEFAULT_DATABASE_PASSWORD}"
        ;;
    R)
        DEFAULT_REDIS_PASSWORD=$OPTARG
        echo "Setting Default Redis Password as ${DEFAULT_REDIS_PASSWORD}"
        ;;
    S)
        ROLE=$OPTARG
        check_role
        echo "Setting Default Redis Password as ${DEFAULT_REDIS_PASSWORD}"
        ;;
    q)
        DATABASE_HOSTNAME=$OPTARG
        echo "Setting Database Hostname as ${DATABASE_HOSTNAME}"
        ;;
    m)
        MANAGER_HOSTNAME=$OPTARG
        echo "Setting Manager Hostname as ${MANAGER_HOSTNAME}"
        ;;
    M)
        DEFAULT_MANAGER_TOKEN=$OPTARG
        echo "Setting Default Manager Token as ${DEFAULT_MANAGER_TOKEN}"
        ;;
    n)
        API_SERVER_HOSTNAME=$OPTARG
        echo "Setting API Server Hostname as ${API_SERVER_HOSTNAME}"
        ;;
    r)
        PROVIDER=$OPTARG
        echo "Setting Agent Provider as ${PROVIDER}"
        ;;
    D)
        START_SERVICES='false'
        ;;
    v)
        set -x
        ;;
    z)
        SERVER_ZONE=$OPTARG
        echo "Setting Server Zone  as ${SERVER_ZONE}"
        ;;
    t)
        DATABASE_SSL='false'
        echo "Setting Database SSL to true"
        ;;
    T)
        DATABASE_PORT=$OPTARG
        echo "Setting Database Port to ${DATABASE_PORT}"
        ;;
    o)
        REDIS_HOSTNAME=$OPTARG
        echo "Setting Redis Hostname to ${REDIS_HOSTNAME}"
        ;;
    I)
        SEED_IMAGES="false"
        PULL_IMAGES="false"
        ;;
    u)
        PULL_IMAGES="false"
        ;;
    w)
        WORKSPACE_IMAGE_TARFILE=$OPTARG
        OFFLINE_INSTALL="true"

        if [ ! -f "$WORKSPACE_IMAGE_TARFILE" ]; then
            echo "FATAL: Workspace image tarfile does not exist: ${WORKSPACE_IMAGE_TARFILE}"
            exit 1
        fi

        echo "Setting workspace image tarfile to ${WORKSPACE_IMAGE_TARFILE}"
	    ;;
    s)
        SERVICE_IMAGE_TARFILE=$OPTARG
        OFFLINE_INSTALL="true"
        PULL_IMAGES="false"

        if [ ! -f "$SERVICE_IMAGE_TARFILE" ]; then
          echo "FATAL: Service image tarfile does not exist: ${SERVICE_IMAGE_TARFILE}"
          exit 1
        fi

        echo "Setting service image tarfile to ${SERVICE_IMAGE_TARFILE}"
        ;;
    *)
        error "Unexpected option ${flag}"
        display_help
        ;;
  esac
done


is_port_ok

if [ "${ACCEPT_EULA}" == "false" ] ;
then
    accept_eula
fi

bash ${KASM_RELEASE}/install_dependencies.sh

id -u kasm &>/dev/null || useradd kasm

# TODO Propmpt the user, or accept a flag for automation
sudo rm -rf ${KASM_INSTALL_BASE}

mkdir -p ${KASM_INSTALL_BASE}/bin
mkdir -p ${KASM_INSTALL_BASE}/certs
mkdir -p ${KASM_INSTALL_BASE}/www
mkdir -p ${KASM_INSTALL_BASE}/conf/nginx/services.d
mkdir -p ${KASM_INSTALL_BASE}/conf/nginx/containers.d
mkdir -p ${KASM_INSTALL_BASE}/conf/database/seed_data
mkdir -p ${KASM_INSTALL_BASE}/conf/app

mkdir -p ${KASM_INSTALL_BASE}/log/nginx
mkdir -p ${KASM_INSTALL_BASE}/log/logrotate

chmod 777 ${KASM_INSTALL_BASE}/log
chmod 777 ${KASM_INSTALL_BASE}/log/nginx
chmod 777 ${KASM_INSTALL_BASE}/log/logrotate
chmod 777 ${KASM_INSTALL_BASE}/conf/nginx/containers.d

sudo openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout ${KASM_INSTALL_BASE}/certs/kasm_nginx.key -out ${KASM_INSTALL_BASE}/certs/kasm_nginx.crt -subj "/C=US/ST=VA/L=None/O=None/OU=DoFu/CN=$(hostname)/emailAddress=none@none.none" 2> /dev/null
chmod 600 ${KASM_INSTALL_BASE}/certs/kasm_nginx.crt

cp -r ${KASM_RELEASE}/conf/app/* ${KASM_INSTALL_BASE}/conf/app/

cp ${KASM_RELEASE}/conf/database/data.sql ${KASM_INSTALL_BASE}/conf/database/
cp ${KASM_RELEASE}/conf/database/seed_data/default_properties.yaml ${KASM_INSTALL_BASE}/conf/database/seed_data/
cp ${KASM_RELEASE}/conf/database/seed_data/default_images_amd64.yaml ${KASM_INSTALL_BASE}/conf/database/seed_data/
cp ${KASM_RELEASE}/conf/database/seed_data/default_images_arm64.yaml ${KASM_INSTALL_BASE}/conf/database/seed_data/
cp ${KASM_RELEASE}/conf/database/seed_data/default_agents.yaml ${KASM_INSTALL_BASE}/conf/database/seed_data/

chmod -R 444 ${KASM_INSTALL_BASE}/conf/database
cp -r ${KASM_RELEASE}/conf/nginx/orchestrator.conf ${KASM_INSTALL_BASE}/conf/nginx/orchestrator.conf
cp -r ${KASM_RELEASE}/conf/nginx/logging.conf ${KASM_INSTALL_BASE}/conf/nginx/logging.conf

mkdir -p ${KASM_INSTALL_BASE}/docker/.conf
cp ${KASM_RELEASE}/docker/*.yaml ${KASM_INSTALL_BASE}/docker/.conf/
cp -r ${KASM_RELEASE}/bin/ ${KASM_INSTALL_BASE}/
cp -r ${KASM_RELEASE}/licenses/ ${KASM_INSTALL_BASE}/
cp  ${EULA_PATH} ${KASM_INSTALL_BASE}/



if [ "${ROLE}" == "all" ] ;
then
    echo "Installing All Services"
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_agent.conf ${KASM_INSTALL_BASE}/conf/nginx/upstream_agent.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/agent.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/agent.conf
    cp ${KASM_RELEASE}/docker/docker-compose-all.yaml ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
    copy_db_config
    set_agent_server_id
    set_provider
    copy_manager_configs
    copy_api_configs
    set_api_hostname
    set_api_server_id
    set_share_id
    set_server_zone
    set_manager_id
    set_listening_port
    create_docker_network
    set_random_database_password
    set_database_password
    set_random_redis_password
    set_redis_password
    set_database_hostname
    set_database_port
    set_database_ssl
    set_redis_hostname
    set_random_manager_token
    set_manager_token
    load_service_images
    load_workspace_images
    base_install

elif [ "${ROLE}" == "app" ] ;
then
    echo "Installing App Role"
    cp ${KASM_RELEASE}/docker/docker-compose-app.yaml ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
    copy_manager_configs
    get_database_hostname
    set_database_hostname
    get_database_password
    set_database_password
    set_database_ssl
    get_redis_password
    set_redis_password
    set_redis_hostname
    set_api_hostname
    set_api_server_id
    set_share_id
    set_server_zone
    set_manager_id
    set_listening_port
    create_docker_network
    DO_DATABASE_INIT='false'
    load_service_images
    base_install

elif [ "${ROLE}" == "agent" ] ;
then
    echo "Installing Agent Role"
    cp -r ${KASM_RELEASE}/conf/nginx/upstream_agent.conf ${KASM_INSTALL_BASE}/conf/nginx/upstream_agent.conf
    cp -r ${KASM_RELEASE}/conf/nginx/services.d/agent.conf ${KASM_INSTALL_BASE}/conf/nginx/services.d/agent.conf
    cp ${KASM_RELEASE}/docker/docker-compose-agent.yaml ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
    get_manager_hostname
    set_manager_hostname
    get_public_hostname
    set_public_hostname
    get_manager_token
    set_manager_token
    set_agent_server_id
    set_provider
    set_listening_port
    create_docker_network
    DO_DATABASE_INIT='false'
    load_service_images
    load_workspace_images

elif [ "${ROLE}" == "db" ] ;
then
    echo "Installing Database Role"
    if [ "${DATABASE_HOSTNAME}" == 'false' ] && [ "${REDIS_HOSTNAME}" == 'false' ]; then
    	cp ${KASM_RELEASE}/docker/docker-compose-db-redis.yaml ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
    elif [ "${DATABASE_HOSTNAME}" == 'false' ]; then
    	cp ${KASM_RELEASE}/docker/docker-compose-db.yaml ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
    elif [ "${REDIS_HOSTNAME}" == 'false' ]; then
    	cp ${KASM_RELEASE}/docker/docker-compose-redis.yaml ${KASM_INSTALL_BASE}/docker/docker-compose.yaml
	fi
    copy_db_config
    create_docker_network
    set_random_database_password
    set_database_password
    set_database_hostname
    set_database_port
    set_database_ssl
    set_redis_hostname
    set_random_redis_password
    set_redis_password
    set_listening_port
    set_random_manager_token
    set_manager_token
    load_service_images
    base_install

else
    exit -1
fi


chmod +x ${KASM_INSTALL_BASE}/bin/*
chmod +x ${KASM_INSTALL_BASE}/bin/utils/*
chmod -R 777 ${KASM_INSTALL_BASE}/conf/nginx

# Remove the symbolic links if they already exits
rm -f /opt/kasm/current
rm -f /opt/kasm/bin
# Create symbolic links to the version just installed
ln -sf ${KASM_INSTALL_BASE} /opt/kasm/current
ln -sf /opt/kasm/current/bin /opt/kasm/bin




if [ "${START_SERVICES}" == "true" ]  ;
then
    echo "Starting Kasm Services"
    ${KASM_INSTALL_BASE}/bin/start
    if [ "${ROLE}" == "all" ] ;
    then
        if [ "${PULL_IMAGES}" == "true" ]  ;
        then
          pull_images
        else
          echo "Not pulling default Workspaces Images."
        fi
    fi
else
    echo "Not starting Kasm Services"
fi




if  [ "${ROLE}" == "agent" ] || [ "${ROLE}" == "all" ] ;
then
    if [[ $(sudo swapon --show) ]]; then
        echo 'Swap Exists'
    else
        printf "\n--------------------------------------------------------------------------------"
        printf "\n                             WARNING  "
        printf "\n--------------------------------------------------------------------------------\n\n"
        echo 'Your system does not have a Swap file or partition. Even with adequate RAM it is'
        echo 'imperative to a have a swap file for Kasm to be stable. You can add a swap file '
        echo 'at any time, see our documentations Resource Allocation Section for more details.'
        printf "\n"
        read -p "Do you want to continue installation? (Swaps may be added at anytime) (y/n)? " choice
        case "$choice" in
          y|Y )
            echo "Finishing Installation..."
            ;;
          n|N )
            echo "Installation Exiting"
            exit 1
            ;;
          * )
            echo "Invalid Response"
            echo "Installation Exiting"
            exit 1
            ;;
        esac
    fi
fi

printf "\n\n"
echo "Installation Complete"
if [ "${DO_DATABASE_INIT}" == "true" ] ;
then
    printf "\n\n"
    echo "Kasm UI Login Credentials"
    printf "\n"
    echo "------------------------------------"
    echo "  username: admin@kasm.local"
    echo "  password: ${DEFAULT_ADMIN_PASSWORD}"
    echo "------------------------------------"
    echo "  username: user@kasm.local"
    echo "  password: ${DEFAULT_USER_PASSWORD}"
    echo "------------------------------------"
    printf "\n"
    echo "Kasm Database Credentials"
    echo "------------------------------------"
    echo "  username: kasmapp"
    echo "  password: ${DEFAULT_DATABASE_PASSWORD}"
    echo "------------------------------------"
    printf "\n"
    echo "Kasm Redis Credentials"
    echo "------------------------------------"
    echo "  password: ${DEFAULT_REDIS_PASSWORD}"
    echo "------------------------------------"
    printf "\n"
    echo "Kasm Manager Token"
    echo "------------------------------------"
    echo "  password: ${DEFAULT_MANAGER_TOKEN}"
    echo "------------------------------------"
    printf "\n\n"
fi


