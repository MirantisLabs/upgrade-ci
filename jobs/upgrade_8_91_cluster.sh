export MIRROR_UBUNTU='deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-updates main universe multiverse|deb http://mirror.seed-cz1.fuel-infra.org/pkgs/ubuntu-latest/ trusty-security main universe multiverse'


BUILD_ID=${CUSTOM_BUILD_ID:-${BUILD_ID}}
JOB_MD5SUM=`echo ${JOB_NAME} | md5sum - | cut -d" " -f1`
BUILD_DIR="${HOME}/workdir/${JOB_MD5SUM}-${BUILD_ID}"

export UPGRADE_FUEL_FROM=8.0
export UPGRADE_FUEL_TO=9.0

export KEYSTONE_PASSWORD=admin1

export UPDATE_MASTER=true

export LOGS_DIR=${BUILD_DIR}/logs

export ISO_PATH=${HOME}/iso/MirantisOpenStack-8.0.iso
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


export ISO_PATH=${HOME}/iso/MirantisOpenStack-8.0.iso
export FUEL_PROPOSED_REPO_URL="http://packages.fuel-infra.org/repositories/centos/liberty-centos7/proposed/x86_64/"
export UPDATE_MASTER=true
export OCTANE_PATCHES="$STABLE8_PATCHES"


rm -rf fuel-qa8.0
git_change_request https://github.com/openstack/fuel-qa stable/8.0 fuel-qa8.0  321611 ${FUEL_QA_STABLE8_PATCHES}
cd fuel-qa8.0

pip install -r fuelweb_test/requirements.txt --upgrade

bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_smoke_backup

)

unset OCTANE_PATCHES


export OCTANE_PATCHES="$STABLE9_PATCHES"
export ISO_PATH=${HOME}/iso/MirantisOpenStack-9.0-RC2.iso
rm -rf fuel-qa-mitaka
git_change_request https://github.com/openstack/fuel-qa stable/mitaka fuel-qa-mitaka 332743 ${FUEL_QA_STABLE9_PATCHES}


(
cd fuel-qa-mitaka
fuel9_fix_devops_requirement | patch -p1
pip install -r fuelweb_test/requirements.txt
pip uninstall -y fuel-devops
(
git clone git://github.com/openstack/fuel-devops.git -b release/2.9
cd fuel-devops
pip install .
)


bash -x ./utils/jenkins/system_tests.sh -t test -w $(pwd) -j fuelweb_test -i $ISO_PATH -k -K -o --group=upgrade_smoke_scale -o --group=upgrade_smoke_new_deployment

)
