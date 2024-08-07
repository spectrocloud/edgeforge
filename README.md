# EdgeForge - Organize your CanvOS configurations

This repository enables you to structure your configuration files for CanvOS:
```
edgeforge/
├─ arg/           .arg files
├─ content/       precached content (optional)
├─ docker/        extra Dockerfile content (optional)
├─ userdata/      user-data files
```

You can then create files in the root of the repo that combine your configuration files for a CanvOS run:

`my-config`
```
EF_CANVOS_TAG=v4.4.6
EF_ARG=ubuntu-2204-standard
EF_DOCKER=open-iscsi                          # optional
EF_USERDATA=custeng-prod
EF_CONTENT=demo                               # optional
EF_CUSTOM_TAG=demo-44-u22                     # optional
EF_ISO_NAME=palette-edge-installer-44-u22     # optional
```

Finally, use `build.sh` to perform a CanvOS run with your desired EdgeForge configuration:
```
Usage:
------
./build.sh [name_of_config] [action(s)]

Example:
--------
./build.sh my-config +iso
./build.sh my-config --push +build-all-images
```

If CanvOS is not yet preset, it will automatically be cloned into the CanvOS subdirectory.
Every run, CanvOS gets reset and a fresh `git checkout` of the desired CanvOS tag/branch happens.
This is to ensure you always work from a clean environment.

If your run outputs an ISO file, it will automatically be retrieved and placed into `./ISO/<name of config>/$ISO_NAME.iso`
