#!/bin/sh
set -x

export JENKINS_URL=${JENKINS_URL:-http://localhost:8080}
export JENKINS_USER=${JENKINS_USER:-admin}
export JENKINS_PASS=${JENKINS_PASS:-admin}
export JENKINS_CLI="java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s ${JENKINS_URL}"

upload_jobs() {
        local git_dir=$1
        test -d ${git_dir}
        pushd
        cd ${git_dir}/jj_configs
        find *  -maxdepth 1 -type d -print | xargs -tI% bash -c "${JENKINS_CLI} create-job '%' --username ${JENKINS_USER} --password ${JENKINS_PASS} < '%/config.xml'"
        popd
}

TMP_DIR="upgrade-ci.$$"

cd /tmp
git clone http://github.com/mirantislabs/upgrade-ci ${TMP_DIR}
upload_jobs ${TMP_DIR}

