export MIRROR_UBUNTU='deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-updates main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-security main universe multiverse'


BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}

JOB_MD5SUM=`echo ${JOB_NAME} | md5sum - | cut -d" " -f1`


BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

# Vars related to whole job:
export LOGS_DIR=${BUILD_DIR}/logs
export NODES_COUNT=10
export ENV_NAME=upgrade_master_7_91_with_cluster_${BUILD_ID}
export VENV_PATH=${BUILD_DIR}/fuel-qa-venv
export KEYSTONE_PASSWORD=admin1
export UPGRADE_FUEL_FROM=7.0
export UPGRADE_FUEL_TO=9.1
export UPGRADE_BACKUP_FILES_LOCAL_DIR=${BUILD_DIR}/backup_files
export UPGRADE_TEST_TEMPLATE=fuelweb_test/tests/tests_upgrade/example_upgrade_scenario.yaml

cd ${BUILD_DIR} || mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

export ISO_PATH=$(download_file_by_magnet `magnet_map 7.0` $BUILD_DIR)

rm -rf ${VENV_PATH}
virtualenv ${VENV_PATH}
. ${VENV_PATH}/bin/activate

pip install git+https://github.com/openstack/fuel-devops@release/2.9

# 7.0 related data:
export FUEL_PROPOSED_REPO_URL=http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos7.0-centos6-fuel/proposed/x86_64
export OCTANE_PATCHES="$STABLE7_PATCHES"
export UPDATE_MASTER=true

export UPDATE_FUEL_MIRROR=http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos7.0-centos6-fuel/snapshots/proposed-latest/x86_64/
export EXTRA_DEB_REPOS="mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/snapshots/7.0-latest mos7.0-proposed main restricted"

# 7.0 actions:
dos.py snapshot-list $ENV_NAME | grep ceph_ha_octane_backup_7 || (
   rm -rf fuel-qa7.0
   git_change_request https://github.com/openstack/fuel-qa stable/7.0 fuel-qa7.0 ${QA_STABLE7_PATCHES}
   cd fuel-qa7.0
   pip install -U -r fuelweb_test/requirements.txt
   # prepare the ceph_ha cluster
   bash -x ./utils/jenkins/system_tests.sh -w $(pwd) -j fuelweb_test -k -K -o --group=prepare_upgrade_ceph_ha_before_backup
   # do backup based on yaml file
   export UPGRADE_CUSTOM_STEP_NAME=step_1
   bash -x ./utils/jenkins/system_tests.sh -w $(pwd) -j fuelweb_test -k -K -o --group=upgrade_custom_backup
)
unset OCTANE_PATCHES
# end of 7.0 actions


# 8.0 related data
deactivate 
export ISO_PATH=$(download_file_by_magnet `magnet_map 8.0` $BUILD_DIR)
. ${VENV_PATH}/bin/activate
export UPDATE_FUEL_MIRROR=http://mirror.seed-cz1.fuel-infra.org/mos-repos/centos/mos8.0-centos7-fuel/snapshots/proposed-latest/x86_64/
export EXTRA_DEB_REPOS='mos-proposed,deb http://mirror.seed-cz1.fuel-infra.org/mos-repos/ubuntu/snapshots/8.0-latest mos8.0-proposed main restricted'
export FUEL_PROPOSED_REPO_URL="http://packages.fuel-infra.org/repositories/centos/liberty-centos7/proposed/x86_64/"
export OCTANE_PATCHES="$STABLE8_PATCHES"
# 8.0 related actions
dos.py snapshot-list $ENV_NAME | grep upgrade_ceph_ha_backup || (
   rm -rf fuel-qa8.0
   git_change_request https://github.com/openstack/fuel-qa stable/8.0 fuel-qa8.0 ${QA_STABLE8_PATCHES}
   cd fuel-qa8.0
   pip install -U -r fuelweb_test/requirements.txt
   # do restore 8.0
   export UPGRADE_CUSTOM_STEP_NAME=step_2
   bash -x ./utils/jenkins/system_tests.sh  -w $(pwd) -j fuelweb_test -k -K -o --group=upgrade_custom_restore
   # backup 8.0 data for next restore
   export UPGRADE_CUSTOM_STEP_NAME=step_3
   bash -x ./utils/jenkins/system_tests.sh  -w $(pwd) -j fuelweb_test -k -K -o --group=upgrade_custom_backup
)
unset OCTANE_PATCHES
# end of 8.0 actions

deactivate
# 9.0 data
export ISO_PATH=$(download_file_by_magnet `magnet_map 9.0` $BUILD_DIR)
. ${VENV_PATH}/bin/activate
# 9.x data
export OCTANE_PATCHES="$STABLE9_PATCHES"
export FUEL_PROPOSED_REPO_URL="http://perestroika-repo-tst.infra.mirantis.net/mos-repos/centos/mos9.0-centos7/os/x86_64/"
curl https://product-ci.infra.mirantis.net/job/9.x.snapshot/lastSuccessfulBuild/artifact/snapshots.sh > 9.x_vars.sh
cat 9.x_vars.sh
source 9.x_vars.sh

export UPDATE_FUEL_MIRROR=$(get_9.x_fuel_mirrors)
export EXTRA_DEB_REPOS=$(get_9.x_mos_ubuntu_mirrors)

(
   rm -rf fuel-qa-mitaka
   git_change_request https://github.com/openstack/fuel-qa stable/mitaka fuel-qa-mitaka ${QA_STABLE9_PATCHES}
   cd fuel-qa-mitaka
   pip install -U -r fuelweb_test/requirements.txt
   
   bash -x ./utils/jenkins/system_tests.sh -w $(pwd) -j fuelweb_test -k -K -o --group=${QA_STABLE9_TESTGROUP}
)
