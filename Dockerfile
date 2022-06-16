ARG CUDA_VER=11.5.1
ARG LINUX_VER=ubuntu18.04
ARG PY_VER=3.8
FROM rapidsai/mambaforge-cuda:${CUDA_VER}-base-${LINUX_VER}-py${PY_VER}

ARG CUDA_VER
ARG LINUX_VER

ARG DEBIAN_FRONTEND=noninteractive

# Add sccache variables
ENV CMAKE_CUDA_COMPILER_LAUNCHER=sccache
ENV CMAKE_CXX_COMPILER_LAUNCHER=sccache
ENV CMAKE_C_COMPILER_LAUNCHER=sccache

# Copy condarc to configure conda build
COPY condarc /opt/conda/.condarc

# Install system packages depending on the LINUX_VER
RUN case "${LINUX_VER}" in \
      "ubuntu"*) \
        PKG_CUDA_VER="$(echo ${CUDA_VER} | cut -d '.' -f1,2 | tr '.' '-')" \
        && apt-get update \
        && apt-get upgrade -y \
        && apt-get install -y --no-install-recommends \
          cuda-gdb-${PKG_CUDA_VER} \
          cuda-nvcc-${PKG_CUDA_VER} \
          wget \
        && rm -rf "/var/lib/apt/lists/*"; \
        ;; \
      "centos"*) \
        PKG_CUDA_VER="$(echo ${CUDA_VER} | cut -d '.' -f1,2 | tr '.' '-')" \
        yum -y update \
        && yum -y install --setopt=install_weak_deps=False \
          cuda-gdb-${PKG_CUDA_VER} \
          cuda-nvcc-${PKG_CUDA_VER} \
          wget \
        && yum clean all; \
        ;; \
      *) \
        echo "Unsupported LINUX_VER: ${LINUX_VER}" && exit 1; \
        ;; \
    esac

# Install gpuci-tools
RUN wget https://github.com/rapidsai/gpuci-tools/releases/latest/download/tools.tar.gz -O - \
  | tar -xz -C /usr/local/bin

# Install CI tools using conda
RUN gpuci_mamba_retry install -y \
  anaconda-client \
  awscli \
  boa \
  git \
  jq \
  ninja \
  sccache

CMD ["/bin/bash"]