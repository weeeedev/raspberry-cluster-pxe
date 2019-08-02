# Dockerized servers fox PXE boot

This can be used if TFTP and NFS servers are not available otherwise.

## Setup

This uses ready-made Docker images for [NFS Server](https://hub.docker.com/r/itsthenetwork/nfs-server-alpine) and [TFTP](https://hub.docker.com/r/pghalliday/tftp). Running NFS in `docker` requires `nfs` kernel module to be loaded in the Docker host (`modprobe nfs`, see the image's Docker Hub page for more details).

Shared files for the servers should go to:

* NFS: `docker/share/`
* TFTP: `docker/share/tftp/`
