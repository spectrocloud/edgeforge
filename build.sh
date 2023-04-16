#!/bin/bash -x

set -xe
source .versions.env

CANVOS_ENV="prod"
ISO_IMAGE_NAME=spectro-edge-installer-$CANVOS_VERSION
IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-3pings}"
INSTALLER_IMAGE=${IMAGE_REPOSITORY}/${ISO_IMAGE_NAME}:${SPECTRO_VERSION}
ISO_IMAGE_ID=palette.io/${ISO_IMAGE_NAME}:${SPECTRO_VERSION}
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
K8S_PROVIDER_VERSION=v1.2.3
KAIROS_VERSION="${KAIROS_VERSION:-v1.5.0}"
BASE_IMAGE=quay.io/kairos/core-ubuntu-22-lts:"${KAIROS_VERSION}"


echo "Building Installer image $INSTALLER_IMAGE from $BASE_IMAGE"
docker build  --build-arg BASE_IMAGE=$BASE_IMAGE \
              --build-arg SPECTRO_VERSION=$SPECTRO_VERSION \
               -t $INSTALLER_IMAGE -f images/Dockerfile .

for k8s_version in ${K8S_VERSIONS//,/ }
do
    IMAGE=${IMAGE_REPOSITORY}/core-ubuntu-22-lts-k3s:$CANVOS_ENV-v${k8s_version}_${K8S_PROVIDER_VERSION}
    docker build --build-arg K8S_VERSION=$k8s_version \
                 --build-arg BASE_IMAGE=$BASE_IMAGE \
                 --build-arg SPECTRO_VERSION=$SPECTRO_VERSION \
                 --build-arg SPECTRO_LUET_VERSION=$SPECTRO_LUET_VERSION \
                 -t $IMAGE \
                 -f images/Dockerfile ./
    if [[ "$PUSH_BUILD" == "true" ]]; then
      echo "Pushing image"
      docker push "$IMAGE"
    fi
done

echo "Building $ISO_IMAGE_NAME.iso from $INSTALLER_IMAGE"

docker rmi $ISO_IMAGE_ID || true
docker tag $INSTALLER_IMAGE $ISO_IMAGE_ID
docker run -v $PWD:/cOS \
            -v /var/run/docker.sock:/var/run/docker.sock \
             -i --rm quay.io/kairos/osbuilder-tools:v0.3.3 --name $ISO_IMAGE_NAME \
             --debug build-iso --date=false $INSTALLER_IMAGE  --local --overlay-iso /cOS/overlay/files-iso  --output /cOS/
docker rmi $ISO_IMAGE_ID
# if [[ "$PUSH_BUILD" == "true" ]]; then
#   echo "Pushing image"
#   docker push "$INSTALLER_IMAGE"
# fi

aws s3 cp $ISO_IMAGE_NAME.iso s3://edgeforge/images/$ISO_IMAGE_NAME-$SPECTRO_VERSION-$CANVOS_ENV.iso --profile gh-runner