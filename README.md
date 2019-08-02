# Raspberry Cluster with PXE boot over TFTP/NFS4

Basic example of how to boot a bunch of Raspberry Pis over network with no SD cards.

This is written with Raspberry Pi 3 Model B+ and Raspbian Stretch in mind.

*Note:* existing DHCP server with ability to set the required TFTP boot options is expected.

## Prerequisites

* (Linux) PC running Docker with `docker-compose` installed
* Raspbian Stretch Lite zip file
* Serial numbers for the Pis in use

## Docker setup

A Dockerized TFTP and NFS4 server are used to provide boot/root files for the Pis. The example here uses public, 3rd party images from Docker Hub. Please direct any issues with those to the respective maintainers.

Setting up the contents for TFTP/NFS:

```bash
./setup_docker_content.sh path-to-raspbian-zip hostname serial nfsip tftpip
```

This will extract, and modify, the contents from Raspbian image to dir the included `docker-compose.yaml` expects. `hostname` here will be the Pis hostname, whereas `nfsip` and `tftpip` are IPs for the machine running those services (in this case, that would be the machine running Docker).

## Raspberry boot

* Set up DHCP to include "DHCP TFTP Server" option pointing to the IP where TFTP is running.
* Fire up Raspberry with no SD card, ethernet connected
