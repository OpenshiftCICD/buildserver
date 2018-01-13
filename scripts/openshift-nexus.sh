#!/bin/bash
# author: Thomas Herzog
# date: 18/01/12

# Source environment
source ./.openshift-env

# Versions
VERSION_NEXUS="3.6.0"

# Execute in script dir
cd $(dirname ${0})

# Creates the nexus service
function create() {
  # Create the nexus service
  oc new-app -f ../templates/nexus.yml \
    -p "SERVICE_NAME=${NEXUS_SERVICE}" \
    -p "NEXUS_VERSION=${VERSION_NEXUS}" \
    -p "MIN_CPU=1000m" \
    -p "MAX_CPU=4000m" \
    -p "MIN_MEMORY=1Gi" \
    -p "MAX_MEMORY=4Gi"
} # create

# Deletes the nexus service
function delete() {
  oc delete all -l app=${NEXUS_SERVICE}
  oc delete secrets -l app=${NEXUS_SERVICE}
  oc delete sa -l app=${NEXUS_SERVICE}
  oc delete pvc -l app=${NEXUS_SERVICE}
  oc delete rolebinding -l app=${NEXUS_SERVICE}
} # delete



function backup() {
  local RESTORE=$1

  local NEXUS_POD=$(oc get pod --selector=deploymentconfig=nexus -o jsonpath='{ .items[0].metadata.name }')
  mkdir -p ${SCRIPT_DIR}/backup/

  read -r -d '' NEXUS_SHELL << EOM
rm -rf /nexus-data/db/*
rm -rf /nexus-data/blobs/*
exit
EOM

  if [ "$RESTORE" =  restore ]
  then
      echo $NEXUS_SHELL | oc rsh ${NEXUS_POD}
      oc cp ${SCRIPT_DIR}/backup/backup ${NEXUS_POD}:/nexus-data/backup
      oc cp ${SCRIPT_DIR}/backup/blobs ${NEXUS_POD}:/nexus-data/blobs
      oc delete pod ${NEXUS_POD}
  else
      oc cp ${NEXUS_POD}:/nexus-data/backup ${SCRIPT_DIR}/backup/backup
      oc cp ${NEXUS_POD}:/nexus-data/blobs ${SCRIPT_DIR}/backup/blobs
  fi
}

function delete_nexus3_repo() {
  local _REPO_ID=$1
  local _NEXUS_USER=$2
  local _NEXUS_PWD=$3
  local _NEXUS_URL=$4

  read -r -d '' _REPO_JSON << EOM
{
    "name" : "remove-$_REPO_ID",
    "type" : "groovy",
    "content" : "repository.getRepositoryManager().delete('$_REPO_ID');"
}
EOM

  curl -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/siesta/rest/v1/script/"
  curl -X POST -H "Content-Type: text/plain" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/siesta/rest/v1/script/remove-$_REPO_ID/run"
}




#############################################################################################################
# FOLLOWING CODE FROM: https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/scripts/nexus-functions
#
# add_nexus3_repo [repo-id] [repo-url] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_repo() {
  local _REPO_ID=$1
  local _REPO_URL=$2
  local _NEXUS_USER=$3
  local _NEXUS_PWD=$4
  local _NEXUS_URL=$5

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_REPO_ID",
  "type": "groovy",
  "content": "repository.createMavenProxy('$_REPO_ID','$_REPO_URL')"
}
EOM

  curl -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/siesta/rest/v1/script/"
  curl -X POST -H "Content-Type: text/plain" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/siesta/rest/v1/script/$_REPO_ID/run"
}


#
# add_nexus3_group_repo [comma-separated-repo-ids] [group-id] [nexus-username] [nexus-password] [nexus-url]
#
function add_nexus3_group_repo() {
  local _REPO_IDS=$1
  local _GROUP_ID=$2
  local _NEXUS_USER=$3
  local _NEXUS_PWD=$4
  local _NEXUS_URL=$5

  read -r -d '' _REPO_JSON << EOM
{
  "name": "$_GROUP_ID",
  "type": "groovy",
  "content": "repository.createMavenGroup('$_GROUP_ID', '$_REPO_IDS'.split(',').toList())"
}
EOM

  curl -H "Accept: application/json" -H "Content-Type: application/json" -d "$_REPO_JSON" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/siesta/rest/v1/script/"
  curl -X POST -H "Content-Type: text/plain" -u "$_NEXUS_USER:$_NEXUS_PWD" "${_NEXUS_URL}/service/siesta/rest/v1/script/$_GROUP_ID/run"
}

#
# add_nexus3_redhat_repos [nexus-username] [nexus-password] [nexus-url]
#
function init-repos() {
  local _NEXUS_USER=$1
  local _NEXUS_PWD=$2

  local _NEXUS_URL=http://$(oc get route nexus -o jsonpath='{.spec.host}')

  add_nexus3_repo redhat-ga https://maven.repository.redhat.com/ga/ $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
  add_nexus3_repo redhat-ea https://maven.repository.redhat.com/earlyaccess/all/ $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
  add_nexus3_repo redhat-techpreview https://maven.repository.redhat.com/techpreview/all $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
  add_nexus3_repo jboss-ce https://repository.jboss.org/nexus/content/groups/public/ $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL

  add_nexus3_group_repo redhat-ga,redhat-ea,redhat-techpreview,jboss-ce,maven-central,maven-releases,maven-snapshots maven-all-public $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL

  delete_nexus3_repo nuget-group $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
  delete_nexus3_repo nuget-hosted $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
  delete_nexus3_repo nuget.org-proxy $_NEXUS_USER $_NEXUS_PWD $_NEXUS_URL
}
#
#####################################################################################################################

${*}
