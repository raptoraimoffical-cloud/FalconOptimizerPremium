Falcon Optimizer — Tools Folder

This folder is for optional bundled helpers/installers that Falcon can launch.

Place files here:
- tools/nvidia-driver-installer/  (your NVIDIA driver installer helper, e.g. setup.exe or installer.exe)
- tools/nv-clean-install/         (your clean-install helper, e.g. NVCleanstall.exe or your preferred tool)

Falcon will look for:
- tools/nvidia-driver-installer/installer.exe  OR setup.exe
- tools/nv-clean-install/nvclean.exe           OR NVCleanstall.exe

If you use different names, update the corresponding tweak JSON in tweaks/apps.utilities.json and tweaks/hardware.gpu.json.
