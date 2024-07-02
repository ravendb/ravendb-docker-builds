ARG QEMU_ARCH
ARG DISTRO_VERSION
FROM multiarch/qemu-user-static:x86_64-${QEMU_ARCH} as qemu
FROM ubuntu:${DISTRO_VERSION} 

ARG QEMU_ARCH
COPY --from=qemu /usr/bin/qemu-${QEMU_ARCH}-static /usr/bin

RUN mkdir /output
RUN apt update \ 
    && apt-get -y dist-upgrade \
    && apt install -y libicu-dev

COPY RavenDB /RavenDB
WORKDIR /RavenDB/Server

CMD ./Raven.Server --info > /output/info.txt