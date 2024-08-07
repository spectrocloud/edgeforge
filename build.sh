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
  echo "./build.sh my-config --push +build-all-images"
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
  echo -e "${GREEN}Settings validated.${NC}"

  echo -e "${GREEN}Switching to CanvOS tag $EF_CANVOS_TAG...${NC}"
  cd CanvOS
  if [ -d build ]; then rm -rf build/; fi
  git reset -q --hard || exit_on_error "Failed to do git reset on CanvOS!"
  git checkout -q $EF_CANVOS_TAG || exit_on_error "Failed to switch to CanvOS tag $EF_CANVOS_TAG"
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
  cp ../userdata/$EF_USERDATA user-data || exit_on_error "Failed to copy ../userdata/$EF_USERDATA to user-data!"
  if [ ! -z "${EF_DOCKER}" ]; then
    echo -e "${GREEN}Adding Dockerfile content to CanvOS Dockerfile...${NC}"
    echo "" >> Dockerfile
    cat ../docker/$EF_DOCKER >> Dockerfile
  fi
  echo -e "${GREEN}Settings successfully copied into CanvOS.${NC}"

  echo -e "${GREEN}Running CanvOS...${NC}"
  ./earthly.sh "${@:2}" || exit_on_error "CanvOS run failed!"
  echo -e "${GREEN}CanvOS completed successfully, checking for ISO outputs...${NC}"
  cd ..
  if [ -n "$(ls -A CanvOS/build 2>/dev/null)" ]; then
    echo -e "${GREEN}CanvOS generated an ISO, moving it to ISO/$1...${NC}"
    mkdir -p ISO/$1
    mv CanvOS/build/* ISO/$1/
  fi
  echo -e "${GREEN}All done!${NC}"
else
  exit_on_error "Specified config $1 not found!"
fi
