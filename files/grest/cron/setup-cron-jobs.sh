#!/bin/bash

err_exit() {
    echo -e "$*" >&2
    echo -e "Exiting...\n" >&2
    pushd -0 >/dev/null && dirs -c
    exit 1
}

CRON_DIR="/etc/cron.d"
USER="$(whoami)"

[[ -z ${CNODE_NAME} ]] && CNODE_NAME='cnode'
CNODE_PATH="/opt/cardano"
CNODE_HOME=${CNODE_PATH}/${CNODE_NAME}

[[ -f "${CNODE_HOME}"/scripts/.env_branch ]] && BRANCH=$(cat "${CNODE_HOME}"/scripts/.env_branch) || BRANCH=master

if ! curl -s -f -m ${CURL_TIMEOUT} "https://api.github.com/repos/cardano-community/guild-operators/branches" | jq -e ".[] | select(.name == \"${BRANCH}\")" &>/dev/null; then
    echo -e "\nWARN!! ${BRANCH} branch does not exist, falling back to alpha branch\n"
    BRANCH=alpha
    echo "${BRANCH}" >"${CNODE_HOME}"/scripts/.env_branch
else
    echo "${BRANCH}" >"${CNODE_HOME}"/scripts/.env_branch
fi

REPO_RAW="https://raw.githubusercontent.com/cardano-community/guild-operators"
URL_RAW="${REPO_RAW}/${BRANCH}"

CRON_SCRIPTS_DIR="${CNODE_HOME}/scripts/cron-scripts"
if [ ! -d CRON_SCRIPTS_DIR ]; then
    mkdir CRON_SCRIPTS_DIR
fi

echo "Setting up stake distribution update job to run every 30 minutes..."

if curl -s -f -m ${CURL_TIMEOUT} -o ${CRON_SCRIPTS_DIR}/stake-distribution-update.sh ${URL_RAW}/files/grest/cron/jobs/stake-distribution-update.sh; then
    echo "Downloaded ${CRON_SCRIPTS_DIR}/stake-distribution-update.sh"
else
    err_exit "ERROR!! Could not download ${haproxy_url}"
fi

STAKE_DISTRIBUTION_UPDATE_JOB="${CRON_DIR}/stake_distribution_update"

if [ -f "$STAKE_DISTRIBUTION_UPDATE_JOB" ]; then
    rm "$STAKE_DISTRIBUTION_UPDATE_JOB"
fi

echo "*/30 * * * * ${USER} /bin/sh ${CRON_SCRIPTS_DIR}/stake-distribution-update.sh"
