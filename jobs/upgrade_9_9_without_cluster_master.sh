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


#export FUEL_PROPOSED_REPO_URL=${FUEL_PROPOSED_REPO_URL}
export FUEL_PROPOSED_REPO_URL=http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos9.0-centos7/os/x86_64/

#. ${VENV_PATH}/bin/activate

test -d ${BUILD_DIR} || {
   mkdir ${BUILD_DIR}
}

cd $BUILD_DIR


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
git_change_request https://github.com/openstack/fuel-qa stable/mitaka fuel-qa-mitaka  332743


(
cd fuel-qa-mitaka
fuel9_fix_devops_requirement | patch -p1
pip install -r fuelweb_test/requirements.txt
pip uninstall -y fuel-devops
(
git clone git://github.com/openstack/fuel-devops.git -b release/2.9
cd fuel-devops
cr_patch `pwd` 326462 327180 327656 331120
pip install .
)


bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_no_cluster_backup
bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_no_cluster_tests

)

