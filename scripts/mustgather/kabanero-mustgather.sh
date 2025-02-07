#!/bin/bash
#
# Run this script to collect debug information

set -Euox pipefail

COMPONENT="kabanero.io"
BIN=oc
LOGS_DIR="${LOGS_DIR:-kabanero-debug}"

# Describe and Get all api resources of component across cluster

APIRESOURCES=$(${BIN} get crds -o jsonpath="{.items[*].metadata.name}" | tr ' ' '\n' | grep ${COMPONENT})

for APIRESOURCE in ${APIRESOURCES[@]}
do
	NAMESPACES=$(${BIN} get ${APIRESOURCE} --all-namespaces=true -o jsonpath='{range .items[*]}{@.metadata.namespace}{"\n"}{end}' | uniq)
	for NAMESPACE in ${NAMESPACES[@]}
	do
		mkdir -p ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}
		${BIN} describe ${APIRESOURCE} -n ${NAMESPACE} > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/describe.log
		${BIN} get ${APIRESOURCE} -n ${NAMESPACE} -o=yaml > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/get.yaml
	done
done


# Collect pod logs, describe & get additional resources

NAMESPACES=(kabanero)
APIRESOURCES=(configmaps pods routes roles rolebindings serviceaccounts services)

for NAMESPACE in ${NAMESPACES[@]}
do
	PODS=$(${BIN} get pods -n ${NAMESPACE} -o jsonpath="{.items[*].metadata.name}")
	mkdir -p ${LOGS_DIR}/${NAMESPACE}/pods
	for POD in ${PODS[@]}
	do
		${BIN} logs --all-containers=true -n ${NAMESPACE} ${POD} > ${LOGS_DIR}/${NAMESPACE}/pods/${POD}.log
	done

	for APIRESOURCE in ${APIRESOURCES[@]}
	do
		mkdir -p ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}
		${BIN} describe ${APIRESOURCE} -n ${NAMESPACE} > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/describe.log
		${BIN} get ${APIRESOURCE} -n ${NAMESPACE} -o=yaml > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/get.yaml
	done
done


# Collect clusterroles and clusterrolebindings

KEY="kabanero"
NAMESPACE="kube-system"

APIRESOURCE="clusterroles"
NAMES=$(${BIN} get ${APIRESOURCE} -o jsonpath="{.items[*].metadata.name}" | tr ' ' '\n' | grep ${KEY})
for NAME in ${NAMES[@]}
do
	mkdir -p ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}
	${BIN} describe ${APIRESOURCE} ${NAME} > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/${NAME}-describe.log
	${BIN} get ${APIRESOURCE} ${NAME} -o=yaml > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/${NAME}.yaml
done

APIRESOURCE="clusterrolebindings"
NAMES=$(${BIN} get ${APIRESOURCE} -o jsonpath="{.items[*].metadata.name}" | tr ' ' '\n' | grep ${KEY})
for NAME in ${NAMES[@]}
do
	mkdir -p ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}
	${BIN} describe ${APIRESOURCE} ${NAME} > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/${NAME}-describe.log
	${BIN} get ${APIRESOURCE} ${NAME} -o=yaml > ${LOGS_DIR}/${NAMESPACE}/${APIRESOURCE}/${NAME}.yaml
done
