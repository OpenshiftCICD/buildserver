#!/bin/bash
# author: Thomas Herzog
# date: 18/01/12

# Execute in script dir
cd $(dirname ${0})

# Source environment
source ./.openshift-env
source ./.openshift-secret-env

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
  create|delete)
    ${1}
    ;;
  *)
    echo "./openshift-secrets.sh [create|delete]"
    ;;
esac
