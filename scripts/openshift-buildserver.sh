#!/bin/bash
# author: Thomas Herzog
# date: 18/01/12

# Execute in script dir
cd $(dirname ${0})

# Source environment
source ./.openshift-env

function create() {
  ./openshift-jenkins.sh create
  ./openshift-nexus.sh create
}

function createDev(){
    ./openshift-secrets.sh create 'admin123' 'admin123' ${HOME}/.ssh/id_rsa http://${NEXUS_SERVICE}:8081/repositories/maven-central
    create
}

function delete() {
  ./openshift-secrets.sh delete
  ./openshift-jenkins.sh delete
  ./openshift-nexus.sh delete
}

function backup(){
  JENKINS_POD=$(oc get pod --selector=deploymentconfig=${JENKINS_SERVICE} -o jsonpath='{ .metadata.name }')
  NEXUS_POD=$(oc get pod --selector=deploymentconfig=nexus -o jsonpath='{ .metadata.name }')
  oc rsync ${JENKINS_POD}:/var/lib/jenkins ~/Workspace/Liwest/backup/
  oc rsync ${NEXUS_POD}:/nexus-data ~/Workspace/Liwest/backup/
}

case "$1" in
  createDev|create|delete)
    ${1}
    ;;
  *)
    echo "./openshift-secrets.sh [create <JENKINS_PASSWORD> <NEXUS_PASSWORD> <SSH_PATH> |delete]"
    ;;
esac
