#!/bin/bash
# author: Thomas Herzog
# date: 18/01/12

# Versions
VERSION_MAVEN="3.5.2"
VERSION_GRADLE="4.4.1"

# Execute in script dir
cd $(dirname ${0})

# Source environment
source ./.openshift-env
source ./.openshift-secret-env

# Create all jenkins resources
function create() {
  # The jenkins service, with custom config
  oc new-app -f ../templates/jenkins.yml \
    -p "JENKINS_SERVICE_HOST=${JENKINS_SERVICE}" \
    -p "JNLP_SERVICE_NAME=${JENKINS_SERVICE}-jnlp" \
    -p "GIT_REPO_URL=${JENKINS_SERVICE_GIT_URL}" \
    -p "GIT_REPO_REF=${JENKINS_SERVICE_GIT_REF}" \
    -p "MAVEN_MIRROR_URL=${MAVEN_MIRROR_URL}" \
    -p "MAVEN_REPOSITORY_URL=${MAVEN_REPOSITORY_URL}" \
    -p "MIN_CPU=1000m" \
    -p "MAX_CPU=2000m" \
    -p "MIN_MEMORY=1" \
    -p "MAX_MEMORY=3" \
    -p "SECRET_GITHUB_SSH=${SECRET_GITHUB_SSH}" \
    -p "SECRET_GITHUB_HOOK=${SECRET_GITHUB_HOOK}" \
    -p "SECRET_NEXUS_SERVICE=${SECRET_NEXUS_SERVICE}" \
    -p "SECRET_JENKINS_SERVICE=${SECRET_JENKINS_SERVICE}"

  # The jenkins slaves
  oc new-app -f ../templates/jenkins-slaves.yml \
    -p "APP_NAME=${JENKINS_SERVICE}" \
    -p "MAVEN_VERSION=${VERSION_MAVEN}" \
    -p "GRADLE_VERSION=${VERSION_GRADLE}" \
    -p "GIT_REPO_URL=${JENKINS_SERVICE_GIT_URL}" \
    -p "GIT_REPO_REF=${JENKINS_SERVICE_GIT_REF}" \
    -p "SECRET_GITHUB_SSH=${SECRET_GITHUB_SSH}" \
    -p "SECRET_GITHUB_HOOK=${SECRET_GITHUB_HOOK}" \
    -p "SECRET_NEXUS_SERVICE=${SECRET_NEXUS_SERVICE}"

  createPipeline
} # create

function createPipeline() {
  # The jenkins slaves
  oc new-app -f ../templates/pipeline.yml \
    -p "PIPE_NAME=${JENKINS_SERVICE}-pipe" \
    -p "APP_NAME=${JENKINS_SERVICE}" \
    -p "GIT_REPO=${APP_SERVICE_GIT_URL}" \
    -p "GIT_REF=${APP_SERVICE_GIT_REF}" \
    -p "SECRET_GITHUB_SSH=${SECRET_GITHUB_SSH}" \
    -p "SECRET_GITHUB_HOOK=${SECRET_GITHUB_HOOK}" \
    -p "JENKINS_FILE_PATH=Jenkinsfile"
} # cretePipeline

# Delete the jenkins pipeline
function deletePipeline() {
  oc delete bc/${JENKINS_SERVICE}-pipe
} # deletePipeline

# Deletes all jenkins resources
function delete(){
  oc delete all -l app=${JENKINS_SERVICE}
  oc delete secrets -l app=${JENKINS_SERVICE}
  oc delete pvc -l app=${JENKINS_SERVICE}
  oc delete bc -l app=${JENKINS_SERVICE}

  deletePipeline
} # delete

case $1 in
   create|createPipeline|delete|deletePipeline)
      $1
      ;;
   *)
     echo "./openshift-jenkins.sh [create|delete|createPipeline|deletePipeline]"
     exit -1
     ;;
esac
