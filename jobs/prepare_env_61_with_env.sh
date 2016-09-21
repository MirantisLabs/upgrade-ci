BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}

JOB_MD5SUM=`echo "${JOB_NAME}" | md5sum - | cut -d" " -f1`

BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export LOGS_DIR=${HOME}/logs
export KEYSTONE_PASSWORD=admin1
export UPDATE_MASTER=true

export NODES_COUNT=12
export ENV_NAME=upgrade_61_8_${BUILD_ID}
export LOGS_DIR=${BUILD_DIR}/logs


#. ${VENV_PATH}/bin/activate

test -d ${BUILD_DIR} || {
   mkdir ${BUILD_DIR}
}

export ISO_PATH=$(download_file_by_magnet `magnet_map 6.1` $BUILD_DIR)

cd $BUILD_DIR


export ADMIN_NODE_CPU=4
export SLAVE_NODE_CPU=4
export OPENSTACK_RELEASE='Ubuntu'
export ADMIN_NODE_MEMORY=4096
export SLAVE_NODE_MEMORY=4096
export NODE_VOLUME_SIZE=80
export ADMIN_NODE_VOLUME_SIZE=200
export INTERFACE_MODEL=e1000


export VENV_PATH="${BUILD_DIR}/fuel-devops-venv/"
rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate




export UPGRADE_FUEL_TO=6.1
export TARBALL_PATH=${HOME}/iso/MirantisOpenStack-7.0-upgrade.tar.lrz
export ISO_PATH=$(download_file_by_magnet `magnet_map 6.1` $BUILD_DIR)

rm -rf fuel-qa6.1
git_change_request https://github.com/openstack/fuel-qa stable/6.1 fuel-qa6.1 331714
cd fuel-qa6.1


pip install -r fuelweb_test/requirements.txt


bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=prepare_os_upgrade
