#!/bin/bash
# author: Thomas Herzog
# date: 18/01/12

# Set by caller parameters
DOCKER_REGISTRY_URL=""
DOCKER_USERNAME=""
DOCKER_PASSWORD=""
DOCKER_EMAIL=""
NEXUS_USERNAME=""
NEXUS_PASSWORD=""
JENKINS_USERNAME=""
JENKINS_PASSWORD=""
SSH_PATH=""

# Execute in script dir
cd $(dirname ${0})

# Source environment
source ./.openshift-env

# Creates teh secrets
function create() {
  # Secret for the private secured docker registry
  oc secrets new-dockercfg ${SECRET_NEXUS_DOCKER_REGISTRY} \
    --docker-server="${DOCKER_REGISTRY_URL}" \
    --docker-username="${DOCKER_USERNAME}" \
    --docker-password="${DOCKER_PASSWORD}" \
    --docker-email="${DOCKER_EMAIL}"

  # Secret for the nexus service
  oc create secret generic ${SECRET_NEXUS_SERVICE} \
    --from-literal=username="${NEXUS_USERNAME}" \
    --from-literal=password="${NEXUS_PASSWORD}"

  # Secret for the github repository
  oc secrets new-sshauth ${SECRET_GITHUB_SSH} --ssh-privatekey="${SSH_PATH}"

  # Secret for the jenkins service
  oc create secret generic ${SECRET_JENKINS_SERVICE} \
    --from-literal=username="${JENKINS_USERNAME}" \
    --from-literal=password="${JENKINS_PASSWORD}"
} # create

# Deletes all secrets
function delete(){
    oc delete secrets/${SECRET_GITHUB_SSH}
    oc delete secrets/${SECRET_NEXUS_SERVICE}
    oc delete secrets/${SECRET_JENKINS_SERVICE}
    oc delete secrets/${SECRET_NEXUS_DOCKER_REGISTRY}
} # delete

case "$1" in
  create)
    if [ -z "${2}" ] || [ -z "${3}" ] || [ -z "${4}" ] || [ -z "${5}" ]; then
      echo "nexus-password | jenkins-password | ssh-path parameters | registry-url -> must be given"
      exit -1
    fi

    # Set environment for secret creation
    NEXUS_USERNAME="admin"
    NEXUS_PASSWORD="${2}"
    DOCKER_REGISTRY_URL="${5}"
    DOCKER_USERNAME="${NEXUS_USERNAME}"
    DOCKER_PASSWORD="${NEXUS_PASSWORD}"
    DOCKER_EMAIL="nexus@openshift-ci-cd.com"
    JENKINS_USERNAME="${NEXUS_USERNAME}"
    JENKINS_PASSWORD="${3}"
    SSH_PATH="${4}"

    create
    ;;
  delete)
      delete
    ;;
  *)
    echo "./openshift-secrets.sh [create <JENKINS_PASSWORD> <NEXUS_PASSWORD> <SSH_PATH> |delete]"
    ;;
esac
