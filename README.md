# NMI Device Nickname Updater

A PowerShell script (plus a `.bat` launcher) that bulk-updates the **device nickname** on one or more NMI Customer-Present Cloud POI devices, such as an Ingenico Link/2500 LE, without deregistering them.

It wraps NMI's Device Management API:

```
POST https://secure.networkmerchants.com/api/v2/devices/update/{poiDeviceId}
```

## Files

| File | Purpose |
| --- | --- |
| `Update-NmiDeviceNickname.ps1` | The script. Validates input, calls the API once per device, and prints a per-device result table. |
| `Update-NmiDeviceNickname.bat` | Launcher that runs the script with `-ExecutionPolicy Bypass`, so you don't have to change your system's execution policy to run an unsigned script. |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- An NMI **Merchant API key** (security key)
- The **POI Device ID** (GUID) of each device you want to rename. This is the `poiDeviceId` returned when the device was registered.

## Usage

### Using the batch file

```bat
Update-NmiDeviceNickname.bat -ApiKey "your_api_key" -Nickname "Front Counter" -DeviceId "414b0420-b31c-4c76-9fc3-8a4f1a6dcffc"
```

### Calling PowerShell directly

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Update-NmiDeviceNickname.ps1 `
    -ApiKey "your_api_key" `
    -Nickname "Front Counter" `
    -DeviceId "414b0420-b31c-4c76-9fc3-8a4f1a6dcffc"
```

### Multiple devices

`-DeviceId` accepts a single ID, a comma-separated string, or a PowerShell array. All of these work:

```powershell
-DeviceId "guid1,guid2,guid3"
-DeviceId "guid1","guid2","guid3"
```

Every device in the list receives the same nickname.

## Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| `-ApiKey` | Yes | NMI Merchant API key, sent as a `Bearer` token. |
| `-Nickname` | Yes | New nickname to apply to every listed device. |
| `-DeviceId` | Yes | One or more POI Device IDs (see above for accepted formats). |
| `-BaseUrl` | No | Override the API base URL. Defaults to `https://secure.networkmerchants.com/api/v2/devices/update`. |

### Nickname rules

NMI requires nicknames to match `^[A-Za-z0-9-_ ]{1,20}$`:

- 1 to 20 characters
- Letters, numbers, spaces, hyphens, and underscores only

The script checks this **before** making any API calls, so an invalid nickname fails immediately instead of producing an error for every device.

## Output and exit codes

The script prints a table with one row per device:

```
DeviceId                              Success Message
--------                              ------- -------
414b0420-b31c-4c76-9fc3-8a4f1a6dcffc     True OK
d352da6e-8772-4433-92f6-a77c4926fd80    False HTTP 404 - ...
```

| Exit code | Meaning |
| --- | --- |
| `0` | All devices updated successfully. |
| `1` | Invalid input, or at least one device failed to update. |

A bad ID in a batch doesn't stop the run. The remaining devices are still processed, and failures are reported in the table.

## Finding your device IDs

- **Merchant Portal:** Settings → License Manager → Registered Devices
- **API:** NMI's Device Estate Management endpoints can list your registered devices and return each `poiDeviceId`. See the [NMI developer docs](https://docs.nmi.com/docs/device-estate-management).

## Security notes

- The API key is passed as a command-line argument, so it can end up in your shell history and in process listings. For anything beyond one-off use, load it from a secure store (Windows Credential Manager, a secrets vault, etc.) into a variable rather than typing it inline or saving it in a scheduled task's arguments.
- Don't commit your API key to this repository.
- `-ExecutionPolicy Bypass` applies only to the single PowerShell process the `.bat` launches. It does not change your machine or user execution policy.

## Limitations

- This only changes the **nickname** shown on the device screen and in License Manager. NMI's API does not expose the serial number/IPSN line of the idle screen, or other idle-screen content, for customization.
- It does not register or deregister devices.

## References

- [Registering Your Device (NMI developer docs)](https://docs.nmi.com/docs/registering-your-device)
- [Customer Present Cloud API (NMI developer docs)](https://docs.nmi.com/docs/device-api-cloud)
- [Link 2500 Quick Start Guide (NMI support)](https://support.nmi.com/hc/en-gb/articles/4416538526097-Link-2500-Quick-Start-Guide)
