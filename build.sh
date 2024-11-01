#!/bin/bash
exit_on_error () {
  echo -e "${RED}${1}${NC}"
  exit 1
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

if [ "$1" == "" ] || [ "$2" == "" ]; then
  echo -e "${YELLOW}"
  echo "Usage:"
  echo "------"
  echo "./build.sh [name_of_config] [action(s)]"
  echo ""
  echo "Example:"
  echo "--------"
  echo "./build.sh my-config +iso"
  echo "./build.sh my-config +build-all-images"
  echo "./build.sh my-config --push +build-provider-images"
  echo -e "${NC}"
  exit_on_error "No config specified!"
elif [ -f $1 ]; then
  if [ ! -d CanvOS ]; then
    echo -e "${GREEN}CanvOS not yet present, cloning repo...${NC}"
    git clone -q https://github.com/spectrocloud/CanvOS || exit_on_error "Failed to clone the CanvOS repository!"
  fi
  echo -e "${GREEN}Found settings for $1, processing...${NC}"
  source $1
  [ -f arg/$EF_ARG ] || exit_on_error "File arg/$EF_ARG not found! Exiting..."
  [ -f userdata/$EF_USERDATA ] || exit_on_error "File userdata/$EF_USERDATA not found! Exiting..."
  [ -z "${EF_DOCKER}" ] || [ -f docker/$EF_DOCKER ] || exit_on_error "File docker/$EF_DOCKER not found! Exiting..."
  [ -z "${EF_CONTENT}" ] || [ -d content/$EF_CONTENT ] || exit_on_error "Directory content/$EF_CONTENT not found! Exiting..."
  [ -z "${EF_SECUREBOOT}" ] || [ -d secureboot/$EF_SECUREBOOT ] || exit_on_error "Directory secureboot/$EF_SECUREBOOT not found! Exiting..."
  [ -z "${EF_EXTRAFILES}" ] || [ -d extrafiles/$EF_EXTRAFILES ] || exit_on_error "Directory extrafiles/$EF_EXTRAFILES not found! Exiting..."
  echo -e "${GREEN}Settings validated.${NC}"

  echo -e "${GREEN}Switching to CanvOS tag $EF_CANVOS_TAG...${NC}"
  cd CanvOS
  if [ -d build ]; then rm -rf build/; fi
  git reset -q --hard || exit_on_error "Failed to do git reset on CanvOS!"
  git clean -q -fdx
  git fetch -q
  git checkout -q $EF_CANVOS_TAG || exit_on_error "Failed to switch to CanvOS tag $EF_CANVOS_TAG"
  sed -i 's/net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=0/' cis-harden/harden.sh
  echo -e "${GREEN}CanvOS preparation complete.${NC}"

  echo -e "${GREEN}Copying settings from $1 to CanvOS...${NC}"
  cp ../arg/$EF_ARG .arg || exit_on_error "Failed to copy ../arg/$EF_ARG to .arg!"
  if [ ! -z "${EF_CUSTOM_TAG}" ]; then
    echo -e "${GREEN}Overriding CUSTOM_TAG parameter in .arg to $EF_CUSTOM_TAG${NC}"
    sed -i '/CUSTOM_TAG/d' .arg
    echo "" >> .arg
    echo "CUSTOM_TAG=${EF_CUSTOM_TAG}" >> .arg
  fi
  if [ ! -z "${EF_ISO_NAME}" ]; then
    echo -e "${GREEN}Overriding ISO_NAME parameter in .arg to $EF_ISO_NAME${NC}"
    sed -i '/ISO_NAME/d' .arg
    echo "" >> .arg
    echo "ISO_NAME=${EF_ISO_NAME}" >> .arg
  fi
  if [ ! -z "${EF_K8S_VERSION}" ]; then
    echo -e "${GREEN}Overriding K8S_VERSION parameter in .arg to $EF_K8S_VERSION${NC}"
    sed -i '/K8S_VERSION/d' .arg
    echo "" >> .arg
    echo "K8S_VERSION=${EF_K8S_VERSION}" >> .arg
  fi
  if [ ! -z "${EF_PE_VERSION}" ]; then
    echo -e "${GREEN}Overriding PE_VERSION parameter in .arg to $EF_PE_VERSION${NC}"
    sed -i '/PE_VERSION/d' .arg
    echo "" >> .arg
    echo "PE_VERSION=${EF_PE_VERSION}" >> .arg
  fi
  cp ../userdata/$EF_USERDATA user-data || exit_on_error "Failed to copy ../userdata/$EF_USERDATA to user-data!"
  if [ ! -z "${EF_DOCKER}" ]; then
    echo -e "${GREEN}Adding Dockerfile content to CanvOS Dockerfile...${NC}"
    echo "" >> Dockerfile
    cat ../docker/$EF_DOCKER >> Dockerfile
  fi
  if [ ! -z "${EF_SECUREBOOT}" ]; then
    echo -e "${GREEN}Copying secureboot/$EF_SECUREBOOT into CanvOS...${NC}"
    mkdir -p secure-boot
    cp -r ../secureboot/$EF_SECUREBOOT/* ./secure-boot/ || exit_on_error "Failed to copy secureboot/$EF_SECUREBOOT into CanvOS!"
  fi

  if [ ! -z "${EF_EXTRAFILES}" ]; then
    echo -e "${GREEN}Copying extrafiles/$EF_EXTRAFILES into CanvOS...${NC}"
    cp -r ../extrafiles/$EF_EXTRAFILES/* . || exit_on_error "Failed to copy extrafiles/$EF_EXTRAFILES into CanvOS!"
  fi
  if [ ! -z "${EF_CONTENT}" ]; then
    CONTENT_DIRS=$(ls -w1 ../content/$EF_CONTENT/)
    for d in $CONTENT_DIRS; do
      echo -e "${GREEN}Moving content/$EF_CONTENT/$d into CanvOS...${NC}"
      mv ../content/$EF_CONTENT/$d ./ || exit_on_error "Failed to move content/$EF_CONTENT/$d into CanvOS!"
    done
  fi
  echo -e "${GREEN}Settings successfully copied into CanvOS.${NC}"

  echo -e "${GREEN}Running CanvOS...${NC}"
  if [ ! -z "${EF_EARTHLY_NATIVE}" ]; then
    if [ "${EF_EARTHLY_NATIVE}" = "yes" ]; then
      earthly "${@:2}"
    fi
  else
    ./earthly.sh "${@:2}"
  fi

  if [ "$?" == "0" ]; then
    echo -e "${GREEN}CanvOS completed successfully, continuing...${NC}"
    echo -e "${GREEN}Checking for ISO outputs...${NC}"
    cd ..
    if [ -n "$(ls -A CanvOS/build 2>/dev/null)" ]; then
      echo -e "${GREEN}CanvOS generated an ISO, moving it to ISO/$1...${NC}"
      mkdir -p ISO/$1
      sudo mv CanvOS/build/* ISO/$1/
    fi
    if [ ! -z "${EF_SECUREBOOT}" ]; then
      echo -e "${GREEN}Syncing CanvOS secure-boot back to secureboot/$EF_SECUREBOOT as contents may have updated...${NC}"
      cp -r CanvOS/secure-boot/* secureboot/$EF_SECUREBOOT/ || echo -e "${RED}Failed to sync secure-boot back to secureboot/$EF_SECUREBOOT!${NC}"
    fi
  else
    echo -e "${RED}CanvOS run failed, performing cleanup tasks for content and/or secureboot if necessary...${NC}"
    cd ..
  fi

  if [ ! -z "${EF_CONTENT}" ]; then
    for d in $CONTENT_DIRS; do
      echo -e "${GREEN}Moving CanvOS/$d back to content/$EF_CONTENT/...${NC}"
      mv CanvOS/$d content/$EF_CONTENT/ || echo -e "${RED}Failed to move CanvOS/$d to content/$EF_CONTENT/!${NC}"
    done
  fi

  echo -e "${GREEN}Run completed.${NC}"
else
  exit_on_error "Specified config $1 not found!"
fi
