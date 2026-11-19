'use strict';
// Hardware profile fixtures in the shape produced by scripts/system-profile.ps1.
const base = {
  isAdmin: true,
  os: { caption: 'Microsoft Windows 11 Pro', build: 26100, ubr: 4000, displayVersion: '24H2' },
  formFactor: 'desktop',
  cpu: { name: 'AMD Ryzen 7 7800X3D 8-Core Processor', vendor: 'amd', cores: 8, threads: 16, x3d: true, x3dDual: false, hybrid: false, x3dDriver: false },
  gpus: [{ name: 'NVIDIA GeForce RTX 4070', pnp: 'PCI\\VEN_10DE&DEV_2786&SUBSYS_00000000&REV_A1\\4&1A2B3C4D&0&0008', driverDate: '2026-10-01', vramGb: 12 }],
  displays: [{ device: '\\\\.\\DISPLAY1', adapter: 'NVIDIA GeForce RTX 4070', resolution: '2560x1440', refreshHz: 240, maxRefreshHz: 240, primary: true }],
  ram: { totalGb: 32, modules: 2, ratedMTs: 6000, configuredMTs: 6000 },
  state: { vbsRunning: false, hvciRunning: false, hags: 2, gameMode: 1, gameDvr: 0, mouseAccel: false, powerPlan: 'Balanced', bcdReadable: true, forcedPlatformClock: false, pagefileMb: 4096, systemDriveFreeGb: 300, resizableBar: true },
  net: { hasWifi: false, wiredUp: true, wifiUp: false }
};

module.exports = {
  desktopNvidia: base,
  desktopX3dDual: {
    ...base,
    cpu: { ...base.cpu, name: 'AMD Ryzen 9 9950X3D 16-Core Processor', cores: 16, threads: 32, x3dDual: true, x3dDriver: true }
  },
  laptopHybrid: {
    ...base,
    formFactor: 'laptop',
    cpu: { name: '13th Gen Intel(R) Core(TM) i7-13700H', vendor: 'intel', cores: 14, threads: 20, x3d: false, x3dDual: false, hybrid: true },
    gpus: [
      { name: 'NVIDIA GeForce RTX 4060 Laptop GPU', pnp: 'PCI\\VEN_10DE&DEV_28E0&SUBSYS_00000000&REV_A1\\4&2B&0&0008', driverDate: '2026-09-01' },
      { name: 'Intel(R) Iris(R) Xe Graphics', pnp: 'PCI\\VEN_8086&DEV_A7A0&SUBSYS_00000000&REV_04\\3&11583659&0&10', driverDate: '2026-05-01' }
    ],
    net: { hasWifi: true, wiredUp: false, wifiUp: true }
  },
  win10Desktop: { ...base, os: { caption: 'Microsoft Windows 10 Pro', build: 19045, ubr: 5000, displayVersion: '22H2' } },
  noGpuInfo: { ...base, gpus: [], displays: [] }
};
