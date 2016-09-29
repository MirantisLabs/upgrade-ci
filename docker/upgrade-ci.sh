#!/bin/sh
set -x

export JENKINS_URL=${JENKINS_URL:-http://localhost:8080}
export JENKINS_USER=${JENKINS_USER:-admin}
export JENKINS_PASS=${JENKINS_PASS:-admin}
export JENKINS_CREDS="--username ${JENKINS_USER} --password ${JENKINS_PASS}"
export JENKINS_CREDS=""
export JENKINS_CLI="java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s ${JENKINS_URL}"



upload_jobs() {
        local git_dir=$1
        test -d ${git_dir}
#        pushd
        cd ${git_dir}/jj_configs
        # TODO check if job is alredy exists (jenkins-cli get-job)
        find *  -maxdepth 1 -type d -print | xargs -tI% bash -c "${JENKINS_CLI} create-job '%' ${JENKINS_CREDS} < '%/config.xml'"
#        popd
}

install_plugins() {
        xargs -tI% ${JENKINS_CLI} install-plugin % ${JENKINS_CREDS}
}

required_plugin_list() {
cat<<EOF
ansible
ansicolor
greenballs
nodelabelparameter
rebuild
timestamper
groovy
EOF
}

TMP_DIR="upgrade-ci.$$"

cd /tmp
git clone http://github.com/mirantislabs/upgrade-ci ${TMP_DIR}
required_plugin_list | install_plugins
upload_jobs ${TMP_DIR}

${JENKINS_CLI} restart ${JENKINS_CREDS}
