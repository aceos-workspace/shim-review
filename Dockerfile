FROM vathpela/fedora-x64-20250818-buildroot:latest

ARG SHIM_VERSION="16.1"
ARG SHIM_REVIEW_TAG="aceos-shim-x64-2025-09-11"
ARG SHIM_BUILD_OPTIONS="POST_PROCESS_PE_FLAGS=-N"
ENV SHIM_IMAGE="shimx64.efi"
ENV WORKSPACE_DIR="/work"
ENV SHIM_REVIEW="https://github.com/aceos-workspace/shim-review.git"
ENV SHIM_REVIEW_DIR="shim-review"

RUN mkdir -p ${WORKSPACE_DIR}
WORKDIR ${WORKSPACE_DIR}

RUN wget https://github.com/rhboot/shim/releases/download/${SHIM_VERSION}/shim-${SHIM_VERSION}.tar.bz2
RUN tar xf shim-${SHIM_VERSION}.tar.bz2

RUN git clone ${SHIM_REVIEW} --branch ${SHIM_REVIEW_TAG} ${SHIM_REVIEW_DIR}

WORKDIR ${WORKSPACE_DIR}/shim-${SHIM_VERSION}

RUN mkdir build-x64 inst cert

RUN cp ${WORKSPACE_DIR}/${SHIM_REVIEW_DIR}/aceos_ca.der ./cert
RUN echo shim.aceos,1,Tencent,shim,${SHIM_VERSION},mail:asukawang@tencent.com >> data/sbat.csv


WORKDIR ${WORKSPACE_DIR}/shim-${SHIM_VERSION}/build-x64
RUN make ${SHIM_BUILD_OPTIONS} TOPDIR=.. DESTDIR=../inst EFIDIR=aceos VENDOR_CERT_FILE=../cert/aceos_ca.der -f ../Makefile install

RUN cp ../inst/boot/efi/EFI/aceos/${SHIM_IMAGE} ${WORKSPACE_DIR}/${SHIM_IMAGE}


WORKDIR ${WORKSPACE_DIR}

RUN objcopy --only-section .sbat -O binary ${SHIM_IMAGE} /dev/stdout
RUN objdump -x ${SHIM_IMAGE} | grep -E 'SectionAlignment|DllCharacteristics'
RUN sha256sum shim-${SHIM_VERSION}.tar.bz2
RUN sha256sum ${SHIM_IMAGE}
RUN sha256sum ${WORKSPACE_DIR}/${SHIM_REVIEW_DIR}/${SHIM_IMAGE}