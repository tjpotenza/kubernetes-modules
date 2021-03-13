Some scratch work from playing with mounting `EBS` volumes:
```bash
###################################################################################################
# Mounting Any Extra EBS Volumes (WIP)
###################################################################################################
retries="6"
interval="10"
data_volume="/dev/sdf"
mount_point="/var/lib/rancher/k3s"

log "Checking whether a mounted volume exists at [$data_volume]..."
for i in $(seq "$retries"); do
    [[ -e "$data_volume" ]] && {
        additional_volume_exists="true"
        break
    } || {
        log "- Attempt $i/$retries: No volume found at [$data_volume]."
    }
    sleep "$interval"
done

if [[ "$additional_volume_exists" == "true" ]]; then
    if [[ "$( lsblk -f -n -o FSTYPE "$data_volume" )" == "" ]]; then
        log "Unformatted drive found at [$data_volume], formatting it..."
        sudo mkfs -t xfs "$data_volume"
    fi

    log "Retrieving UUID for [$data_volume]..."
    uuid=$(lsblk -n -o UUID "$data_volume")

    log "Mounting [$data_volume] to [$mount_point]..."
    echo "UUID=$uuid  $mount_point  xfs  defaults,nofail  0  2" | sudo tee -a "/etc/fstab" > "/dev/null"

else
    log "No additional volume found, using root file system."
fi

log "Creating k3s data directory at [$mount_point], and mounting all volumes..."
sudo mkdir -p "$mount_point"
sudo mount -a
```