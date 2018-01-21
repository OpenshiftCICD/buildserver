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


case $1 in
   create|delete)
      $1
      ;;
   *)
     echo "./openshift-nexus.sh [create|delete]"
     exit -1
     ;;
esac
