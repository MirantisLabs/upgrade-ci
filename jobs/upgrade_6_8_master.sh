BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}

JOB_MD5SUM=`echo "${JOB_NAME}" | md5sum - | cut -d" " -f1`

BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export LOGS_DIR=${HOME}/logs
export KEYSTONE_PASSWORD=admin1
export UPDATE_MASTER=true
export MAKE_SNAPSHOT=true

export VENV_PATH=${BUILD_DIR}/fuel-devops-venv-2.5/

export ISO_PATH=${HOME}/iso/MirantisOpenStack-6.0.iso
export NODES_COUNT=12
export ENV_NAME=upgrade_6_8_${BUILD_ID}
export LOGS_DIR=${BUILD_DIR}/logs


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
export NODE_VOLUME_SIZE=80
export ADMIN_NODE_VOLUME_SIZE=200
export INTERFACE_MODEL=e1000


rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate

rm -rf fuel-main6.0
git_change_request https://github.com/openstack/fuel-main stable/6.0 fuel-main6.0 331688



(

cd fuel-main6.0


pip install -r fuelweb_test/requirements.txt


(
pip uninstall -y devops
git_change_request git://github.com/openstack/fuel-devops.git stable fuel-devops-stable 332045
cd fuel-devops-stable
pip install -U .
)
#

bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=promo_bvt
)

deactivate

VENV_PATH="${BUILD_DIR}/fuel-devops-venv/"
rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate



(

export UPGRADE_FUEL_FROM=6.0
export UPGRADE_FUEL_TO=6.1
export TARBALL_PATH=${HOME}/iso/MirantisOpenStack-6.1-upgrade.tar.lrz
export ISO_PATH=${HOME}/iso/MirantisOpenStack-6.1.iso

rm -rf fuel-qa6.1
git_change_request https://github.com/openstack/fuel-qa stable/6.1 fuel-qa6.1 ${QA_STABLE61_PATCHES}	

cd fuel-qa6.1

pip install -r fuelweb_test/requirements.txt

bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_ha_one_controller

)

echo "UPDATE devops_node SET role = CASE WHEN name LIKE 'slave%' THEN 'fuel_slave' ELSE 'fuel_master' END" | sudo -u postgres psql fuel_devops

(

export UPGRADE_FUEL_FROM=6.1
export UPGRADE_FUEL_TO=7.0
export TARBALL_PATH=${HOME}/iso/MirantisOpenStack-7.0-upgrade.tar.lrz
export ISO_PATH=${HOME}/iso/MirantisOpenStack-7.0.iso

rm -rf fuel-qa7.0
git_change_request https://github.com/openstack/fuel-qa stable/7.0 fuel-qa7.0 ${QA_STABLE8_PATCHES}
cd fuel-qa7.0

pip install -r fuelweb_test/requirements.txt

fuel7_change_upgrade_step | patch -p1
fuel7_change_backup_workflow | patch -p1

export UPDATE_MASTER=true

bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_ceph_ha_7_0

export UPGRADE_FUEL_FROM=7.0
export UPGRADE_FUEL_TO=8.0

export FUEL_PROPOSED_REPO_URL="http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos7.0-centos6-fuel/proposed/x86_64"


bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_ceph_ha_backup

)

deactivate

VENV_PATH="${BUILD_DIR}/fuel-devops-venv-8.0/"
rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate

(
export ISO_PATH=${HOME}/iso/MirantisOpenStack-8.0.iso
export FUEL_PROPOSED_REPO_URL="http://packages.fuel-infra.org/repositories/centos/liberty-centos7/proposed/x86_64/"
export UPDATE_MASTER=true

rm -rf fuel-qa8.0
git_change_request https://github.com/openstack/fuel-qa stable/8.0 fuel-qa8.0 331702
cd fuel-qa8.0

pip install -r fuelweb_test/requirements.txt


bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_ceph_ha_restore -o --group=upgrade_old_nodes

)

