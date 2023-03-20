#!/bin/bash

set -e
set -u

if [ $VAULT == "true" ]
then
    # Auth Vault
    export VAULT_TOKEN=$(vault write -field=token auth/kubernetes/login \
        role=vault_backups \
        jwt=$(cat /run/secrets/kubernetes.io/serviceaccount/token))

    createDatabaseEnvironment
fi

createDatabaseEnvironment() {
    getMicroserviceName=$(vault kv list -format=json secret/e2e/sunburst/ | jq -c -r '.[]') 
    for microservice in ${getMicroserviceName[@]}
    do     
        echo "${microservice%/}" 
        if [[ $(vault kv get secret/$ENVIRONMENT/sunburst/$microservice/postgres) ]]
           pgDb=$(vault kv get -format=json secret/$ENVIRONMENT/sunburst/$microservice/postgres | jq -c -r '.data.data.pg_database')     
           pgUser=$(vault kv get -format=json secret/$ENVIRONMENT/sunburst/$microservice/postgres | jq -c -r '.data.data.pg_user')   
           pgPassword=$(vault kv get -format=json secret/$ENVIRONMENT/sunburst/$microservice/postgres | jq -c -r '.data.data.pg_password')   
           create_user_and_database "$pgDb" "$pgUser" "$pgPassword"
        fi
    done

}

function create_user_and_database() {
	local database=$1
    local user=$2
    local pw=$3
	echo "  Creating user and database '$database'"
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
	    CREATE USER $user PASSWORD $pw;
	    CREATE DATABASE $database;
	    GRANT ALL PRIVILEGES ON DATABASE $database TO $user;
EOSQL
}



if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
		create_user_and_database $db
	done
	echo "Multiple databases created"
fi


