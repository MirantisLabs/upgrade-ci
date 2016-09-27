#!/bin/bash

# physical devs
pvcreate /dev/sdb /dev/sdc --zero y --yes
# volume group
vgcreate vms /dev/sdb /dev/sdc --yes
# volume for original disk
lvcreate -L 10T -n images vms /dev/sdc --yes
# volume for cache
lvcreate -L 185G -n images_cache vms /dev/sdb --yes
# volume for metadata
lvcreate -L 512M -n images_cache_meta vms /dev/sdb --yes
# create cache-pool
lvconvert --type cache-pool --cachemode writethrough --poolmetadata vms/images_cache_meta vms/images_cache --yes
# create lv with cache
lvconvert --type cache --cachepool vms/images_cache vms/images --yes

touch $1