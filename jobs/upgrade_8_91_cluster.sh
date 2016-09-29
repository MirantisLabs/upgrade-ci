export MIRROR_UBUNTU='deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-updates main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-security main universe multiverse'


BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}
JOB_MD5SUM=`echo ${JOB_NAME} | md5sum - | cut -d" " -f1`
BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export UPGRADE_FUEL_FROM=8.0
export UPGRADE_FUEL_TO=9.0

export KEYSTONE_PASSWORD=admin1

export UPDATE_MASTER=true

export LOGS_DIR=${BUILD_DIR}/logs

export ISO_PATH=$(download_file_by_magnet `magnet_map 8.0` $BUILD_DIR)
export NODES_COUNT=12
export ENV_NAME=upgrade_cluster_8_91_${BUILD_ID}
export VENV_PATH=${BUILD_DIR}/fuel-qa-venv

export OCTANE_PATCHES="$STABLE8_PATCHES"
export ALWAYS_CREATE_DIAGNOSTIC_SNAPSHOT=false

cd ${BUILD_DIR} || mkdir ${BUILD_DIR}
cd ${BUILD_DIR}



rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate


(

export UPDATE_FUEL_MIRROR="http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos8.0-centos7-fuel/proposed/x86_64/"
export EXTRA_DEB_REPOS="mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/8.0 mos8.0-proposed main restricted"


export ISO_PATH=$(download_file_by_magnet `magnet_map 8.0` $BUILD_DIR)
export FUEL_PROPOSED_REPO_URL="http://packages.fuel-infra.org/repositories/centos/liberty-centos7/proposed/x86_64/"
export UPDATE_MASTER=true
export OCTANE_PATCHES="$STABLE8_PATCHES"


rm -rf fuel-qa8.0
git_change_request https://github.com/openstack/fuel-qa stable/8.0 fuel-qa8.0  ${FUEL_QA_STABLE8_PATCHES}
cd fuel-qa8.0
(
git clone git://github.com/openstack/fuel-devops.git -b release/2.9
cd fuel-devops
pip install .
)
bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=${QA_STABLE8_TESTGROUP}

)

unset OCTANE_PATCHES


export OCTANE_PATCHES="$STABLE9_PATCHES"
export ISO_PATH=$(download_file_by_magnet `magnet_map 9.0` $BUILD_DIR)
export FUEL_PROPOSED_REPO_URL="http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos9.0-centos7/os/x86_64/"
curl https://product-ci.infra.mirantis.net/job/9.x.snapshot/lastSuccessfulBuild/artifact/snapshots.sh > 9.x_vars.sh
cat 9.x_vars.sh
source 9.x_vars.sh

export UPDATE_FUEL_MIRROR=$(get_9.x_fuel_mirrors)
export EXTRA_DEB_REPOS=$(get_9.x_mos_ubuntu_mirrors)

rm -rf fuel-qa-mitaka
git_change_request https://github.com/openstack/fuel-qa stable/mitaka fuel-qa-mitaka ${FUEL_QA_STABLE9_PATCHES}


(
cd fuel-qa-mitaka
pip uninstall -y fuel-devops
(
git clone git://github.com/openstack/fuel-devops.git -b release/2.9
cd fuel-devops
pip install .
)


bash -x ./utils/jenkins/system_tests.sh -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=${QA_STABLE9_TESTGROUP}

)
