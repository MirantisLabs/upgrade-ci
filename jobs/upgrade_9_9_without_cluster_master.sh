. ${HOME}/.bash_profile

BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}

JOB_MD5SUM=`echo "${JOB_NAME}" | md5sum - | cut -d" " -f1`

BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export LOGS_DIR=${HOME}/logs
export KEYSTONE_PASSWORD=admin1
export UPDATE_MASTER=true

export VENV_PATH=${BUILD_DIR}/fuel-devops-venv

export ISO_PATH=${HOME}/iso/MirantisOpenStack-9.0.iso
export NODES_COUNT=7
export ENV_NAME=backup_restore_9_NO_CLUSTER_${BUILD_ID}
export LOGS_DIR=${BUILD_DIR}/logs
export MAKE_SNAPSHOT=True


test -d ${BUILD_DIR} || {
   mkdir ${BUILD_DIR}
}

cd $BUILD_DIR
curl https://product-ci.infra.mirantis.net/job/9.x.snapshot/lastSuccessfulBuild/artifact/snapshots.sh > 9.x_vars.sh
cat 9.x_vars.sh
. 9.x_vars.sh

export UPDATE_FUEL_MIRROR=$(get_9.x_fuel_mirrors)
export EXTRA_DEB_REPOS=$(get_9.x_mos_ubuntu_mirrors)


export ADMIN_NODE_CPU=4
export SLAVE_NODE_CPU=4
export OPENSTACK_RELEASE='Ubuntu'
export ADMIN_NODE_MEMORY=4096
export SLAVE_NODE_MEMORY=4096
export NODE_VOLUME_SIZE=40
export ADMIN_NODE_VOLUME_SIZE=60
export INTERFACE_MODEL=e1000
rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate

rm -rf fuel-qa-mitaka
# 332743 have bug?
git_change_request https://github.com/openstack/fuel-qa stable/mitaka fuel-qa-mitaka ${FUEL_QA_MITAKA_PATCHES}
export OCTANE_PATCHES="$OCTANE_PATCHES"


(
cd fuel-qa-mitaka
(
git clone git://github.com/openstack/fuel-devops.git -b release/2.9
cd fuel-devops
pip install .
)

bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_no_cluster_backup
bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_no_cluster_tests

)

