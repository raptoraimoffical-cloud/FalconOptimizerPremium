import json, re, os

root = os.getcwd()

catalog_path = os.path.join(root, 'tweaks', 'processlab.services.catalog.json')
with open(catalog_path, 'r', encoding='utf-8') as f:
    catalog = json.load(f)

items = catalog.get('items', [])
by_svc = { (e.get('serviceName') or '').lower(): e for e in items if e.get('serviceName') }
existing = set(k for k in by_svc.keys() if k)

TELEMETRY_SERVICES = {
    'diagtrack', 'dmwappushservice', 'mapsbroker', 'wercplsupport', 'wersvc', 'wdisystemhost', 'wdiservicehost',
    'ndu', 'cdpsvc', 'cdpusersvc', 'dusmsvc',
}
STORE_UWP_SERVICES = {
    'appxsvc', 'clipsvc', 'installservice', 'gamingservices', 'gamingservicesnet', 'xblgamesave',
    'xboxnetapisvc', 'xboxgipsvc', 'wsappx', 'tokenbroker', 'licensemanager', 'pushnotificationsuser', 'wpnservice', 'wpnuserservice',
    'unistoresvc', 'userdatasvc', 'phonesvc', 'pimindexmaintenancesvc', 'cbdhsvc',
}
UPDATE_SERVICES = {
    'wuauserv', 'waasmedicsvc', 'dosvc', 'bits'
}
NETWORK_SERVICES = {
    'nlasvc', 'lanmanworkstation', 'lanmanserver', 'sharedaccess', 'policyagent', 'ikeext', 'nettcpportsharing',
    'p9rdrservice', 'peerdistsvc', 'lmhosts', 'ssdpsrv', 'upnphost',
}
SENSOR_SERVICES = {
    'lfsvc', 'sensrsvc', 'sensordataservice', 'sensorservice'
}
PRINT_SCAN_SERVICES = {
    'stisvc', 'wiarpc', 'spooler'
}
MEDIA_SHARING_SERVICES = {
    'wmpnetworksvc', 'frameserver', 'captureservice', 'bcastdvruserservice'
}


def classify_category(name: str) -> str:
    n = name.lower()
    if n in TELEMETRY_SERVICES or 'telemetry' in n:
        return 'Telemetry / Tracking'
    if n in STORE_UWP_SERVICES or 'xbox' in n or 'gamingservices' in n:
        return 'Store / Xbox / UWP'
    if n in UPDATE_SERVICES or 'update' in n:
        return 'Windows Update / Servicing'
    if n in NETWORK_SERVICES or any(k in n for k in ['tcp', 'iphlpsvc', 'netprofm']):
        return 'Networking / Delivery'
    if n in SENSOR_SERVICES or 'sensor' in n or 'orientation' in n:
        return 'Sensors / Device Presence'
    if n in PRINT_SCAN_SERVICES or 'print' in n or 'fax' in n:
        return 'Printing / Imaging'
    if n in MEDIA_SHARING_SERVICES or 'media' in n or 'homegroup' in n:
        return 'Media Sharing / HomeGroup'
    if 'nv' in n or 'nvidia' in n:
        return 'GPU / Vendor Services'
    if 'steam' in n or 'epic' in n:
        return 'Launchers / Game Clients'
    return 'General / Misc Services'


def default_modes_for_source(source: str, expansion_start_type: str | None = None):
    source = source.lower()
    if source in ('processlab-main', 'falcon-bat'):
        return {"safe": "unchanged", "competitive": "disabled", "extreme": "disabled"}
    st = (expansion_start_type or '').lower()
    if st == 'manual':
        comp = ext = 'manual'
    elif st == 'automatic':
        comp = ext = 'automatic'
    else:
        comp = ext = 'disabled'
    return {"safe": "unchanged", "competitive": comp, "extreme": ext}


def risk_for_service(name: str) -> str:
    n = name.lower()
    if n in UPDATE_SERVICES:
        return 'Danger'
    if n in NETWORK_SERVICES:
        return 'Warning'
    if n in STORE_UWP_SERVICES:
        return 'Warning'
    if n in TELEMETRY_SERVICES or n in SENSOR_SERVICES or n in PRINT_SCAN_SERVICES or n in MEDIA_SHARING_SERVICES:
        return 'Safe'
    return 'Warning'


def build_conditions(name: str):
    n = name.lower()
    return {
        "requiresLocalAccount": False,
        "breaksMicrosoftStore": n in STORE_UWP_SERVICES,
        "breaksMicrosoftAccountLogin": False,
        "laptopUnsafe": n in SENSOR_SERVICES,
        "desktopOnly": False,
        "minWindowsVersion": None,
        "maxWindowsVersion": None,
    }


def make_display_name(svc: str) -> str:
    return svc


def make_description(name: str, category: str) -> str:
    base = "[Focus: FPS, Latency] "
    if category == 'Telemetry / Tracking':
        return base + "Reduce background diagnostics and telemetry collection to lower background activity during gaming."
    if category == 'Store / Xbox / UWP':
        return base + "Trim Microsoft Store / Xbox / UWP helpers that are not required for a dedicated local gaming account."
    if category == 'Windows Update / Servicing':
        return base + "Reduce automatic update and remediation activity while gaming. May delay Windows updates."
    if category == 'Networking / Delivery':
        return base + "Disable auxiliary network discovery/delivery components that can add background network noise."
    if category == 'Sensors / Device Presence':
        return base + "Disable orientation/sensor stack that is rarely needed on a stationary gaming PC."
    if category == 'Printing / Imaging':
        return base + "Disable legacy printing and imaging services to trim background footprint if you do not print while gaming."
    if category == 'Media Sharing / HomeGroup':
        return base + "Disable media sharing / HomeGroup style services to cut background CPU and network chatter."
    if category == 'GPU / Vendor Services':
        return base + "Disable non-essential GPU companion services to reduce background processes while keeping drivers installed."
    if category == 'Launchers / Game Clients':
        return base + "Disable auto-start background launchers so only the running game stays active."
    return base + "Tune this Windows service for a dedicated gaming session based on Process Lab mode."


# collect service definitions from sources
services: dict[str, dict] = {}

# BAT baselines
for label, path in (( 'processlab-main', os.path.join(root, 'scripts', 'processlab-main-script.bat') ),
                    ( 'falcon-bat',     os.path.join(root, 'scripts', 'falcon-disable-services.bat') )):
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            m = re.search(r'^sc\s+config\s+([^\s]+)', line, re.IGNORECASE)
            if not m:
                continue
            svc = m.group(1).strip()
            key = svc.lower()
            d = services.setdefault(key, { 'name': svc, 'sources': [] })
            d['sources'].append({ 'source': label, 'startType': None })

# JSON tweak files
for fname, source in ((os.path.join(root, 'tweaks', 'debloat.services.json'), 'debloat'),
                      (os.path.join(root, 'tweaks', 'expansion.services.json'), 'expansion')):
    if not os.path.exists(fname):
        continue
    with open(fname, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for item in data.get('items', []):
        for key in ('apply', 'revert'):
            steps = (item.get(key) or {}).get('steps') or []
            for step in steps:
                if not isinstance(step, dict):
                    continue
                if not str(step.get('type', '')).startswith('service.'):
                    continue
                svc = str(step.get('name') or '').strip()
                if not svc:
                    continue
                st = str(step.get('startType') or step.get('startupType') or step.get('mode') or step.get('value') or '').strip()
                key = svc.lower()
                d = services.setdefault(key, { 'name': svc, 'sources': [] })
                d['sources'].append({ 'source': source, 'startType': st })


# build new catalog entries
for key, meta in sorted(services.items()):
    if not key or key in existing:
        continue
    svc_name = meta['name']
    # pick a primary source (prefer BAT baselines so they become core Process Lab entries)
    primary = None
    for s in meta['sources']:
        if s['source'] in ('processlab-main', 'falcon-bat'):
            primary = s
            break
    if primary is None:
        primary = meta['sources'][0]

    modes = default_modes_for_source(primary['source'], primary.get('startType'))
    category = classify_category(svc_name)
    risk = risk_for_service(svc_name)

    entry = {
        "id": f"svc_auto_{svc_name.lower()}",
        "serviceName": svc_name,
        "displayName": make_display_name(svc_name),
        "category": category,
        "tags": ["FPS", "Latency"],
        "defaultModes": modes,
        "revertStartType": "manual",
        "riskLevel": risk,
        "requiresAdmin": True,
        "conditions": build_conditions(svc_name),
        "description": make_description(svc_name, category),
        "notes": "Auto-imported from existing Falcon scripts and service tweak JSON. Review in Custom matrix before applying Extreme mode on a new system."
    }
    items.append(entry)

catalog['items'] = items

with open(catalog_path, 'w', encoding='utf-8') as f:
    json.dump(catalog, f, indent=2)

print(f"Added/kept {len(items)} catalog entries (was {len(by_svc)})")
