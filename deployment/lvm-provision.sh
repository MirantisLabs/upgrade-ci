#!/bin/bash

# physical devs
pvcreate /dev/sdb /dev/sdc
pvscan
# volume group
vgcreate vms /dev/sdb /dev/sdc
vgscan
# volume for original disk
lvcreate -L 10T -n images vms /dev/sdc
# volume for cache
lvcreate -L 185G -n images_cache vms /dev/sdb
# volume for metadata
lvcreate -L 512M -n images_cache_meta vms /dev/sdb
# create cache-pool
lvconvert --type cache-pool --cachemode writethrough --poolmetadata vms/images_cache_meta vms/images_cache -y
# create lv with cache
lvconvert --type cache --cachepool vms/images_cache vms/images

touch $1