#!/bin/bash
# author: Thomas Herzog
# date: 18/01/12

# Execute in script dir
cd $(dirname ${0})

# Source environment
source ./.openshift-env

function create() {
  ./openshift-secrets.sh create
  ./openshift-jenkins.sh create
  ./openshift-nexus.sh create

  # describe build configs to get webhook urls
  oc describe bc/${JENKINS_SERVICE}
  oc describe bc/jenkins-slave-maven3
  oc describe bc/jenkins-slave-gradle
  oc describe bc/${JENKINS_SERVICE}-pipe
}

function createDev() {
  # in the cloud we cannot create it that way
  oc new-app -f ../templates/jenkins-sa.yml \
    -p "JENKINS_SERVICE_HOST=${JENKINS_SERVICE}"

  create
}

function delete() {
  ./openshift-secrets.sh delete
  ./openshift-jenkins.sh delete
  ./openshift-nexus.sh delete
}

function deleteDev() {
    # in the cloud we cannot delete it that way
    oc delete sa -l app=${JENKINS_SERVICE}
    oc delete rolebinding -l app=${JENKINS_SERVICE}

    delete
}

case "$1" in
  create|delete|createDev|deleteDev)
    ${1}
    ;;
  *)
    echo "./openshift-buildserver.sh [create|delete|createDev|deleteDev]"
    ;;
esac
