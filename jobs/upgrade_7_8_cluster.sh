export MIRROR_UBUNTU='deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-updates main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-security main universe multiverse'


BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}

JOB_MD5SUM=`echo ${JOB_NAME} | md5sum - | cut -d" " -f1`


BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export UPGRADE_FUEL_FROM=7.0
export UPGRADE_FUEL_TO=8.0

export KEYSTONE_PASSWORD=admin1

export UPDATE_FUEL_MIRROR="http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos7.0-centos6-fuel/snapshots/proposed-latest/"
export EXTRA_DEB_REPOS="mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/snapshots/7.0-latest/ mos7.0-proposed main restricted"
export UPDATE_MASTER=true

export LOGS_DIR=${BUILD_DIR}/logs

export ISO_PATH=${HOME}/iso/MirantisOpenStack-7.0.iso
export NODES_COUNT=9
export ENV_NAME=upgrade_MOS_7_8_${BUILD_ID}
export VENV_PATH=${BUILD_DIR}/fuel-qa-venv
export FUEL_PROPOSED_REPO_URL="http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos7.0-centos6-fuel/proposed/x86_64"
export OCTANE_PATCHES="$STABLE7_PATCHES"
export ALWAYS_CREATE_DIAGNOSTIC_SNAPSHOT=false
export MAKE_SNAPSHOT=true




cd ${BUILD_DIR} || mkdir ${BUILD_DIR}
cd ${BUILD_DIR}



rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate



(
   rm -rf fuel-qa7.0
   git_change_request https://github.com/openstack/fuel-qa stable/7.0 fuel-qa7.0 ${FUEL_QA_STABLE7_PATCHES}
   cd fuel-qa7.0

   pip install -r fuelweb_test/requirements-devops-source.txt --upgrade
   bash -x ./utils/jenkins/system_tests.sh -N -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_ceph_ha_backup
)
unset OCTANE_PATCHES

(
   
   
export UPDATE_FUEL_MIRROR="http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos8.0-centos7-fuel/snapshots/proposed-latest/"
export EXTRA_DEB_REPOS="mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/snapshots/8.0-latest/ mos8.0-proposed main restricted"


export ISO_PATH=${HOME}/iso/MirantisOpenStack-8.0.iso
export FUEL_PROPOSED_REPO_URL="http://packages.fuel-infra.org/repositories/centos/liberty-centos7/proposed/x86_64/"
export UPDATE_MASTER=true
export OCTANE_PATCHES="$STABLE8_PATCHES"


rm -rf fuel-qa8.0
git_change_request https://github.com/openstack/fuel-qa stable/8.0 fuel-qa8.0 ${FUEL_QA_STABLE8_PATCHES}
cd fuel-qa8.0
pip install -r fuelweb_test/requirements-devops-source.txt --upgrade

bash -x ./utils/jenkins/system_tests.sh -N -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_cloud_no_live_migration
)

