#!/bin/bash

ORGANISMS_COUNT="SELECT COUNT(1) FROM organism;"
ORGANISMS_PUBLISHED_COUNT="SELECT COUNT(public_mode) FROM organism WHERE public_mode='t';"
ORGANISMS_QUERY="SELECT common_name, genus, species, public_mode FROM organism;"
USERS_COUNT="SELECT COUNT(1) FROM grails_user;"
USERS_QUERY="SELECT grails_user.id, role.name AS role_name, inactive, first_name, last_name, username FROM grails_user JOIN grails_user_roles ON grails_user.id = grails_user_roles.user_id JOIN role ON grails_user_roles.role_id = role.id;"
TOKENS_COUNT="SELECT COUNT(DISTINCT client_token) AS client_token_count FROM preference;"
TOKENS_LATEST="SELECT COALESCE((SELECT 'last update on ' || last_updated::date as update_day FROM preference ORDER BY update_day DESC LIMIT 1), '-') AS result;"

# optionally specify path to the file listing apollo instances as the first argument
LIST_OF_INSTANCES="${1:-list_of_apollo_instances.txt}"

# Check if the file exists before proceeding
if [[ ! -f "$LIST_OF_INSTANCES" ]]; then
  echo "Error: File '$LIST_OF_INSTANCES' not found."
  exit 1
fi

while read REMOTE_HOST; do
    #echo "$REMOTE_HOST"
    #echo ""
    echo -n "$REMOTE_HOST Organisms: "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$ORGANISMS_COUNT" | tr -d '\n'
    echo -n "; published: "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$ORGANISMS_PUBLISHED_COUNT"
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$ORGANISMS_QUERY"
    echo ""
    echo -n "$REMOTE_HOST Users: "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$USERS_COUNT"
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$USERS_QUERY"
    echo ""
    echo -n "$REMOTE_HOST Client tokens: "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$TOKENS_COUNT" | tr -d '\n'
    echo -n "; "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$TOKENS_LATEST"
    echo ""
    echo "-----------------"
    echo ""
done <$LIST_OF_INSTANCES

