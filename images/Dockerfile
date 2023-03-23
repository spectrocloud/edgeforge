############################Do not edit below this line##################################
ARG BASE_IMAGE_TAG=v1.5.0
ARG BASE_IMAGE=quay.io/kairos/core-ubuntu-22-lts:v1.5.0
ARG IMAGE_REPOSITORY=3pings/ubuntu-k3s
ARG SPECTRO_VERSION=v3.3.0
FROM gcr.io/spectro-dev-public/stylus-framework:${SPECTRO_VERSION} as spectro-base
FROM ghcr.io/kairos-io/provider-k3s:v1.2.3  as provider-k3s

FROM $BASE_IMAGE
ARG BASE_IMAGE_TAG
ARG IMAGE_REPOSITORY
ARG BASE_IMAGE_NAME=core-ubuntu-22-lts
ARG BASE_IMAGE
ARG SPECTRO_VERSION
ARG K8S_VERSION=1.25.2-k3s1

ARG ARCH=amd64
ENV ARCH=${ARCH}
COPY --from=spectro-base / /
COPY --from=provider-k3s / /

RUN mkdir -p /etc/luet/repos.conf.d && \
    luet repo add spectro --type docker --url gcr.io/spectro-dev-public/luet-repo  --priority 1 -y && \
    luet repo update


RUN luet install -y  k8s/k3s@$K8S_VERSION && luet cleanup



ENV OS_ID=${BASE_IMAGE_NAME}-k3s
ENV OS_NAME=$OS_ID:${SPECTRO_VERSION}
ENV OS_REPO=${IMAGE_REPOSITORY}
ENV OS_VERSION=${K8S_VERSION}_${SPECTRO_VERSION}
ENV OS_LABEL=${BASE_IMAGE_TAG}_${K8S_VERSION}_${SPECTRO_VERSION}
RUN envsubst >/etc/os-release </usr/lib/os-release.tmpl

## Copy any custom files by placing in the directory specified below
COPY overlay/files/ /
############################Do not edit above this line##################################

###########################Add any other image customizations here #######################
## Uncomment the below commands to upgrade the base image at the time of building. Warning this can cause unknown issues not verified in the original images
   
# RUN apt-get update && apt-get upgrade -y
   
    
#Examples
# To install the nginx package from ubuntu or opensuse repos
#RUN zypper refresh && zypper install nginx
# or
#RUN apt-get update && apt-get instal nginx

##########################################################################################
# Clear cache
RUN rm -rf /var/cache/*