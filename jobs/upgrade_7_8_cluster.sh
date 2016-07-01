. ${HOME}/.bash_profile

export MIRROR_UBUNTU='deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-updates main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-security main universe multiverse'


BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}

JOB_MD5SUM=`echo ${JOB_NAME} | md5sum - | cut -d" " -f1`


BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export UPGRADE_FUEL_FROM=7.0
export UPGRADE_FUEL_TO=8.0

export KEYSTONE_PASSWORD=admin1

export UPDATE_FUEL_MIRROR="http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos7.0-centos6-fuel/proposed/x86_64/"
export EXTRA_DEB_REPOS="mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/7.0 mos7.0-proposed main restricted"
export UPDATE_MASTER=true

export LOGS_DIR=${BUILD_DIR}/logs

export ISO_PATH=${HOME}/iso/MirantisOpenStack-7.0.iso
export NODES_COUNT=9
export ENV_NAME=upgrade_MOS_7_8_${BUILD_ID}
export VENV_PATH=${BUILD_DIR}/fuel-qa-venv
export FUEL_PROPOSED_REPO_URL="http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos7.0-centos6-fuel/proposed/x86_64"
export OCTANE_PATCHES="$STABLE7_PATCHES"
export ALWAYS_CREATE_DIAGNOSTIC_SNAPSHOT=false




cd ${BUILD_DIR} || mkdir ${BUILD_DIR}
cd ${BUILD_DIR}



rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate



(
   rm -rf fuel-qa7.0
   git_change_request https://github.com/openstack/fuel-qa stable/7.0 fuel-qa7.0
   cd fuel-qa7.0

   pip install -r ./fuelweb_test/requirements.txt --upgrade
   bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_ceph_ha_backup
)
unset OCTANE_PATCHES

(
   
   
export UPDATE_FUEL_MIRROR="http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos8.0-centos7-fuel/proposed/x86_64/"
export EXTRA_DEB_REPOS="mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/8.0 mos8.0-proposed main restricted"


export ISO_PATH=${HOME}/iso/MirantisOpenStack-8.0.iso
export FUEL_PROPOSED_REPO_URL="http://packages.fuel-infra.org/repositories/centos/liberty-centos7/proposed/x86_64/"
export UPDATE_MASTER=true
export OCTANE_PATCHES="$STABLE8_PATCHES"


rm -rf fuel-qa8.0
git_change_request https://github.com/openstack/fuel-qa stable/8.0 fuel-qa8.0 335380 321611
cd fuel-qa8.0

pip install -r fuelweb_test/requirements.txt --upgrade

bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_old_nodes
)

