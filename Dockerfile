#hadolint global ignore=SC2016,SC2164,DL3005,DL3008,DL3015,DL3042

FROM nvidia/cuda:12.1.1-devel-rockylinux8 AS cuda
SHELL ["/bin/bash", "-xeu", "-o", "pipefail", "-c"]

RUN --mount=type=cache,target=/var/cache/dnf <<-'EOS'
    sed -i -r \
        -e 's!mirrorlist=!#mirrorlist=!g' \
	-e 's!#(baseurl=.*)/\$contentdir/\$releasever/!\1/vault/rocky/8.8/!g' \
	/etc/yum.repos.d/*.repo
    dnf -y distro-sync --disablerepo=cuda
EOS

# https://gitlab.com/nvidia/container-images/cuda/-/blob/master/dist/12.1.1/ubuntu2204/devel/cudnn8/Dockerfile
ENV NV_CUDNN_VERSION=8.9.2.26
ENV NV_CUDNN_PACKAGE_NAME=libcudnn8
ENV NV_CUDNN_PACKAGE=libcudnn8-$NV_CUDNN_VERSION-1+cuda12.1
ENV NV_CUDNN_PACKAGE_DEV=libcudnn8-devel-$NV_CUDNN_VERSION-1+cuda12.1
LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y install $NV_CUDNN_PACKAGE $NV_CUDNN_PACKAGE_DEV

# https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/12.1.1/ubuntu2204/devel/Dockerfile
ENV NV_LIBNCCL_PACKAGE_NAME=libnccl
ENV NV_LIBNCCL_PACKAGE_VERSION=2.20.5-1
ENV NV_LIBNCCL_PACKAGE=$NV_LIBNCCL_PACKAGE_NAME-$NV_LIBNCCL_PACKAGE_VERSION+cuda12.4
ENV NV_LIBNCCL_DEV_PACKAGE_NAME=libnccl-devel
ENV NV_LIBNCCL_DEV_PACKAGE_VERSION=2.20.5-1
ENV NV_LIBNCCL_DEV_PACKAGE=$NV_LIBNCCL_DEV_PACKAGE_NAME-$NV_LIBNCCL_DEV_PACKAGE_VERSION+cuda12.4
ENV NCCL_VERSION=2.20.5-1

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y install $NV_LIBNCCL_PACKAGE $NV_LIBNCCL_DEV_PACKAGE

RUN --mount=type=cache,target=/var/cache/dnf <<-'EOS'
    dnf -y install gcc gcc-c++
    dnf -y install ncurses-compat-libs zlib-devel libxml2-devel
    dnf -y install libedit-devel --enablerepo=powertools
    dnf -y install llvm-devel
EOS

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y install gcc-toolset-12-gcc gcc-toolset-12-gcc-c++

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf -y install git curl

