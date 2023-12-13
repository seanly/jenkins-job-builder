#!/bin/bash

DEBUG=${DEBUG:-false}

if [ $DEBUG == true ]; then
set -x
fi

DRY_RUN=${DRY_RUN:-true}
BASE_PATH=`dirname $0`
JOBS_DIR=${JOBS_PATH:-"${BASE_PATH}/jobs/"}
TEMPLATES_DIR=${BASE_PATH}/templates/

SKIP_UPDATE=${SKIP_UPDATE:-true}

export JENKINS_USER_ID=${JENKINS_USR:-admin}
export JENKINS_API_TOKEN=${JENKINS_PSW:-jenkins}
export JENKINS_URL=${JENKINS_URL:-https://jenkins.opsbox.dev}

export CACHE_DIR=${BASE_PATH}/.cache

# 0. download jenkins-cli.jar 
echo "--//INFO: download jenkins-cli.jar"
if [ ! -f ./jenkins-cli.jar ]; then
    wget $JENKINS_URL/jnlpJars/jenkins-cli.jar
fi

_jenkinsCli="java -jar jenkins-cli.jar -s ${JENKINS_URL} -webSocket"
mkdir -p ${CACHE_DIR}

function createPipelineJob() {
    _folderName=$1
    _configFile=$2
    _job=$3
    # 3. check job is exist (create/update)
    _=`${_jenkinsCli} list-jobs ${_folderName} |grep ${_job}`
    _jobExist=$?
    
    _jobConfigYaml=`cat ${_configFile} | yq ".jobs.[] | select(.type==\"pipeline\") | select(.name==\"${_job}\")"`
    echo "$_jobConfigYaml" > ${CACHE_DIR}/${_folderName}/${_job}.yaml

    # pip install jinja2-cli
    # 4. create job.xml in .cache dir
    jinja2 ${TEMPLATES_DIR}/pipeline.xml.j2 ${CACHE_DIR}/${_folderName}/${_job}.yaml -o ${CACHE_DIR}/${_folderName}/${_job}.xml

    # 5. update or create job
    
    echo "--//INFO: ---console---"
    if [ "x$_jobExist" == "x0" ]; then
        if [ $SKIP_UPDATE == true ]; then
            echo "[skip] job: ${_folderName}/${_job}"
        else
            echo "[update job]: ${_folderName}/${_job}"
            cat ${CACHE_DIR}/${_folderName}/${_job}.xml | ${_jenkinsCli} update-job ${_folderName}/${_job}
        fi
    else
        echo "[create] job: ${_folderName}/${_job}"
        cat ${CACHE_DIR}/${_folderName}/${_job}.xml | ${_jenkinsCli} create-job ${_folderName}/${_job}
    fi
}

function createJobs() {
    _folderName=$1
    _configFile=$2

    # 2. get jobs in folder config.yaml 
    _jobs=`cat ${_configFile} | yq '.jobs.[].name'`
    echo "--//INFO: [${_folderName}] ${_configFile} jobs list:"
    echo "${_jobs}"

    if [ ${DRY_RUN} != true ]; then
        for _job in ${_jobs}
        do
            createPipelineJob ${_folderName} ${_configFile} ${_job}
        done
    fi

}

function createFolder() {
    _folderName=$1
    _=`${_jenkinsCli} list-jobs | grep ${_folderName}`
    _folderExist=$?

    if [ "x$_folderExist" != "x0" ]; then
        echo "--//INFO: create folder ${_folderName}"
        cat ${TEMPLATES_DIR}/folder.xml | ${_jenkinsCli} create-job ${_folderName}
    fi
}

function createJobs2() {
    _folder=$1

    _folderName=`basename ${_folder}`
    echo "--//INFO: folder: ${_folderName} "
    mkdir -p ${CACHE_DIR}/${_folderName}

    createFolder ${_folderName}

    for _file in ${_folder}/*
    do
        if [ -d "${_file}" ]; then
            # create jobs
            createJobs2 ${_file}
        elif [ -f "${_file}" ]; then
            createJobs ${_folderName} ${_file}
        fi
    done

}

createJobs2 ${JOBS_DIR}