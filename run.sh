#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set +u

export BORG_BASE_DIR=/config
export BORG_CACHE_DIR=${BORG_BASE_DIR}/cache
export BORG_PASSPHRASE=$(bashio::config 'borg_passphrase')
export BORG_REPO=""

export _BORG_TOBACKUP=/backup/borg_unpacked
export _BORG_SSH_KNOWN_HOSTS=${BORG_BASE_DIR}/known_hosts
export _BORG_SSH_KEY=${BORG_BASE_DIR}/keys/borg_backup
export _BORG_USER=$(bashio::config 'borg_user')
export _BORG_HOST=$(bashio::config 'borg_host')
export _BORG_REPO_NAME=$(bashio::config 'borg_repo_name')
export _BORG_COMPRESSION=$(bashio::config 'borg_compression')
export _BORG_BACKUP_DEBUG="$(bashio::config 'borg_backup_debug')"
export _BORG_DEBUG=''

export borg_error=0

export BORG_RSH="ssh -o UserKnownHostsFile=${_BORG_SSH_KNOWN_HOSTS} -o StrictHostKeyChecking=accept-new -i ${_BORG_SSH_KEY} $(bashio::config 'borg_ssh_params' "--")"

mkdir -p "$(dirname "${_BORG_SSH_KEY}")" ${BORG_CACHE_DIR}

##### passwords crap
if [[ $BORG_PASSPHRASE == "null" ]]; then
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
    unset BORG_PASSPHRASE
fi
# set zstd as default compression
if [[ "$_BORG_COMPRESSION" == "null" ]]; then
    _BORG_COMPRESSION="zstd"
fi

if [[ "$_BORG_BACKUP_DEBUG" == "true" ]]; then
    _BORG_DEBUG="--debug"
fi

function set_borg_repo_path {
    bashio::log.debug "Setting BORG_REPO"

    # Construct repository URL from parts
    if [[ $_BORG_USER != "null" ]]; then
        BORG_REPO="${_BORG_USER}@${_BORG_HOST}:${_BORG_REPO_NAME}"
    else
        BORG_REPO="${_BORG_HOST}/${_BORG_REPO_NAME}"
    fi
    bashio::log.debug "BORG_REPO set"
    return
}

function generate_ssh_key {
    if ! bashio::fs.file_exists "${_BORG_SSH_KEY}"; then
        bashio::log.info "Generating borg backup ssh keys..."
        ssh-keygen -P '' -f ${_BORG_SSH_KEY}
        bashio::log.info "key generated"
    fi
}

function show_ssh_key {
    bashio::log.info "Your ssh key to use for borg backup host"
    bashio::log.info "************ SNIP **********************"
    echo
    cat ${_BORG_SSH_KEY}.pub
    echo
    bashio::log.info "************ SNIP **********************"
}

function init_borg_repo {
    if ! bashio::fs.directory_exists "${BORG_BASE_DIR}/.config/borg/security"; then
        bashio::log.info "Initializing backup repository"
        borg init --encryption=repokey-blake2 --debug
    fi
}

function borg_create_backup {
    export BACKUP_TIME=$(date  +'%Y-%m-%d-%H:%M')
    bashio::log.info "Creating snapshot"
    ha backups new --name borg-${BACKUP_TIME} --raw-json --no-progress |tee /tmp/borg_backup_$$
    bashio::log.info "Snapshot done"
    export SNAP_RES=$(jq < /tmp/borg_backup_$$ .result -r)
    # if it is not ok something failed and should be logged anyway
    if [[ "$SNAP_RES" != "ok" ]]; then
        bashio::log.error "Failed creating ha snapshot"
        exit 1
    fi
    export SNAP_SLUG=$(jq < /tmp/borg_backup_$$ -r .data.slug)
    mkdir -p ${_BORG_TOBACKUP}/${SNAP_SLUG}
    tar -C ${_BORG_TOBACKUP}/${SNAP_SLUG} -xf /backup/${SNAP_SLUG}.tar
    for targz in ${_BORG_TOBACKUP}/${SNAP_SLUG}/*.tar.gz ; do
                TGZDIR=$(echo ${targz}|sed -e 's/.tar.gz//g')
                mkdir -p ${TGZDIR}
                tar -C ${TGZDIR} -zxf  $targz
                rm -f $targz # remove compressed file
    done

    bashio::log.info "Start borg create"
    borg create ${_BORG_DEBUG} --compression ${_BORG_COMPRESSION} --stats ::"${BACKUP_TIME}" ${_BORG_TOBACKUP}/${SNAP_SLUG}
    bashio::log.info "End borg create --stats..."

    # cleanup
    rm -rf  ${_BORG_TOBACKUP} /tmp/borg_backup_$$
    ha backups remove "$SNAP_SLUG"
}

if [[ $borg_error -gt 0 ]];then
    bashio::log.warning "error state bailing out..."
    exit 1
fi
generate_ssh_key
set_borg_repo_path

init_borg_repo
show_ssh_key
borg_create_backup
