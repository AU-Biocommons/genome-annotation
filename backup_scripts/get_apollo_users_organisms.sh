#!/bin/bash

ORGANISMS_COUNT="SELECT COUNT(1) FROM organism;"
ORGANISMS_QUERY="SELECT common_name, genus, species FROM organism;"
USERS_COUNT="SELECT COUNT(1) FROM grails_user;"
USERS_QUERY="SELECT grails_user.id, role.name AS role_name, inactive, first_name, last_name, username FROM grails_user JOIN grails_user_roles ON grails_user.id = grails_user_roles.user_id JOIN role ON grails_user_roles.role_id = role.id;"

LIST_OF_INSTANCES="/mnt/backup00/list_of_apollo_instances.txt"

while read REMOTE_HOST; do
    #echo "$REMOTE_HOST"
    #echo ""
    echo -n "$REMOTE_HOST Organisms: "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$ORGANISMS_COUNT"
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$ORGANISMS_QUERY"
    echo ""
    echo -n "$REMOTE_HOST Users: "
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$USERS_COUNT"
    psql -d apollo-production -h $REMOTE_HOST -U backup_user -tAc "$USERS_QUERY"
    echo ""
    echo "-----------------"
    echo ""
done <$LIST_OF_INSTANCES

