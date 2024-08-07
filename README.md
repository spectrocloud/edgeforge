# EdgeForge - Organize your CanvOS configurations

This repository enables you to structure your configuration files for CanvOS:
```
edgeforge/
├─ arg/           .arg files
├─ content/       precached content directories (optional)
├─ docker/        extra Dockerfile content files (optional)
├─ secureboot/    Trusted Boot directories (optional)
├─ userdata/      user-data files
my-config         A file that references specific combinations of the above
my-config-2       Another file that references specific combinations of the above
```

You can then create files in the root of the repo that combine your configuration files for a CanvOS run:

`my-config`
```
EF_CANVOS_TAG=v4.4.6
EF_ARG=ubuntu-2204-k8s-129
EF_DOCKER=open-iscsi                          # optional
EF_USERDATA=custeng-prod
EF_SECUREBOOT=demo                            # optional
EF_CONTENT=demo                               # optional
EF_CUSTOM_TAG=demo-44-u22                     # optional
EF_ISO_NAME=palette-edge-installer-44-u22     # optional
```

The example above would expect the following content to exist:
```
edgeforge/
├─ arg/
│  ├─ ubuntu-2204-k8s-129                     .arg file with your desired OS + K8S config
├─ content/
│  ├─ demo/                                   must contain a content-xxxxxxxx subdirectory with precached conent
│  │  ├─ content-2955e6ac/                    precached content previously generated with palette-edge CLI
├─ docker/
│  ├─ open-iscsi                              additional Dockerfile content to be add onto the CanvOS Dockerfile
├─ secureboot/
│  ├─ demo/                                   directory containing all that needs to go into the secure-boot subdirectory of CanvOS
│  │  ├─ enrollment/
│  │  ├─ exported-keys/
│  │  ├─ private-keys/
│  │  ├─ public-keys/
├─ userdata/
│  ├─ custeng-prod                            user-data with your desired config
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

You can pass any legal actions for CanvOS as the 2nd, 3rd, etc parameters, for example:
```
+iso                       Build an ISO only
+build-provider-images     Build images only, no ISO
+build-all-images          Build all images and the ISO
```

If CanvOS is not yet preset, it will automatically be cloned into the CanvOS subdirectory.
Every run, CanvOS gets reset and a fresh `git checkout` of the desired CanvOS tag/branch happens.
This is to ensure you always work from a clean environment.

If your run outputs an ISO file, it will automatically be retrieved and placed into `./ISO/<name of config>/$ISO_NAME.iso`
