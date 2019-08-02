#!/usr/bin/env bash

set -eEuo pipefail

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 path-to-raspbian-zip hostname serial nfsip tftpip"
  exit 1
fi

RASPBIAN_ZIP=${1}
RASPBIAN_HOSTNAME=${2}
RASPBIAN_SERIAL=${3}
NFS_IP=${4}
TFTP_IP=${5}

# Get current script dir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

RASPBIAN_BOOT_DIR=${SCRIPT_DIR}/docker/share/tftp/${RASPBIAN_SERIAL}/
RASPBIAN_ROOT_DIR=${SCRIPT_DIR}/docker/share/${RASPBIAN_HOSTNAME}/

cleanup() {
  echo "Cleaning up"

  if [ ! -z ${LOOP+x} ]; then
    sudo umount ${LOOP}p1
    sudo umount ${LOOP}p2
  fi
  
  sudo rm -rf ${TMPDIR}
}

echo "Creating tempdir"
TMPDIR=$(mktemp -d)

trap cleanup EXIT

setup_content() {
  cd ${TMPDIR}
  echo "Extracting raspbian zip"
  unzip ${RASPBIAN_ZIP}
  RASPBIAN_IMG=$(find . -type f -iname "*raspbian*.img" |head -n1)

  echo "Mounting raspbian partitions (uses 'sudo'!)"
  LOOP=$(sudo losetup --show -fP ${RASPBIAN_IMG})
  mkdir -p {raspbian_root,raspbian_boot}
  sudo mount ${LOOP}p1 raspbian_boot/
  sudo mount ${LOOP}p2 raspbian_root/

  echo "Copying content"
  mkdir -p ${RASPBIAN_BOOT_DIR} ${RASPBIAN_ROOT_DIR}
  rsync -ax raspbian_boot/ ${RASPBIAN_BOOT_DIR}/
  rsync -ax raspbian_root/ ${RASPBIAN_ROOT_DIR}/
}

configure_boot() {
  echo "Copy bootcode to tftp root"
  cp ${RASPBIAN_BOOT_DIR}/bootcode.bin ${RASPBIAN_BOOT_DIR}/../

  echo "Setup cmdline.txt for NFS4 boot"
  echo "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=${NFS_IP}:/${RASPBIAN_HOSTNAME}/,vers=4.1,proto=tcp,port=2049 rw ip=dhcp elevator=deadline rootwait plymouth.ignore-serial-consoles" > ${RASPBIAN_BOOT_DIR}/cmdline.txt

  echo "Enable SSH on boot"
  touch ${RASPBIAN_BOOT_DIR}/ssh
}

configure_raspbian() {
  echo "Setting hostname"
  echo ${RASPBIAN_HOSTNAME} > ${RASPBIAN_ROOT_DIR}/etc/hostname
  sed -i "s/raspberrypi/${RASPBIAN_HOSTNAME}/g" ${RASPBIAN_ROOT_DIR}/etc/hosts

  echo "Remove SD card mounts from fstab"
  sed -i "/mmcblk/d" ${RASPBIAN_ROOT_DIR}/etc/fstab
  sed -i "/PARTUUID/d" ${RASPBIAN_ROOT_DIR}/etc/fstab

  echo "Add /boot mount to fstab"
  echo "${NFS_IP}:tftp/${RASPBIAN_SERIAL} /boot nfs4 defaults,nofail,noatime 0 2" >> ${RASPBIAN_ROOT_DIR}/etc/fstab
}

setup_content
configure_boot
configure_raspbian
echo "Done"
