# Sony LinkBuds S (WF-LS900N): getting a mismatched single earbud to pair, by flashing firmware over USB-C

**TL;DR:** A left earbud from a different pair would not pair with my right earbud. The case flashed orange 3 times as soon as the lid opened, and the Sony initialize never completed. I reflashed the odd earbud with the official 4.3.1 firmware over USB-C through the Sony charging case, using `yusen.exe` (a Sony HID service tool). After that the normal Sony initialize completed (4 green flashes), and the two buds paired to my phone as one set.

No Bluetooth, no patched app and no proxy. Just the case, a USB-C data cable and a Windows PC.

> ⚠️ **Disclaimer:** This is unofficial and may void your warranty. An interrupted or wrong flash can brick an earbud. I only flashed the earbud I could afford to lose. Do this at your own risk.

---

## The situation

- **Pair A:** a left and a right earbud on firmware 4.3.1. The left one was faulty. Their original case had been destroyed by water, and they lived in a third-party charging case.
- **Earbud B:** a single left earbud from another pair, in its original Sony case. Its right partner was gone.
- **Goal:** use earbud B with pair A's right earbud.

### Symptoms

- B + A-right in the Sony case: **3 orange flashes, repeating, as soon as the lid opens.** They stop when the lid closes.
- A-left + A-right in the same Sony case: solid orange (charging) and no fault. So the case is fine.
- B alone in the Sony case: solid orange, no fault. So B is fine on its own.
- Sony initialize (lid open, hold the back button about 15 s) with B + A-right: the LED goes dark, then slow orange blinking, then solid orange, then **back to 3 orange flashes. It never completed.**
- B could not be seen by a phone on its own.
- The third-party case showed no flashes. That turned out to mean nothing, because it's a charge-only case with no data or logic. It doesn't even show up on USB.

### What I found with the USB tool before flashing

| | Earbud B (single L) | A-left | A-right |
|---|---|---|---|
| Firmware (`get mainver`) | **Ver 0431** | Ver 0431 | Ver 0431 |
| Battery | healthy | healthy | healthy |

**All three earbuds were already on 4.3.1**, so the firmware **version** was not the mismatch. Even so, reflashing the same version is what fixed it. My guess is that a fresh flash clears some stale state on the earbud, probably its memory of its old partner. That's a guess, but the before-and-after was very clear.

---

## What you need

1. **Windows PC** and a **USB-C data cable** (not a charge-only cable).
2. **The genuine Sony LinkBuds S charging case.** It must show up on USB. Third-party cases won't work.
3. **`yusen.exe` + `hidapi.dll`** from the WF-1000XM5 updater repo: <https://github.com/MKobra/WF-1000XM5-firmware-updater>
   - `yusen.exe` v0.13 (build 20210322) lists **HDX-2948, HDX-2953, HDX-2950** as supported models. **HDX-2950 is the LinkBuds S** (Sony service ID 2950).
   - SHA-256 of the files I used:
     - `yusen.exe`: `2E0CCD0B9EFFC7E3919F93D4ADC758024BE6AE9430B92B595054426EBD20D29B`
     - `hidapi.dll`: `998F77198D34FEEC9CD398B9B3FE7DB6D48C26E6FC92BE85916F482B623B52C5`
4. **The 32-bit Visual C++ 2012 runtime (`msvcr110.dll`, x86).** See the gotcha below.
5. **Firmware** from the MDR_Proxy firmware mirror: <https://github.com/lzghzr/MDR_Proxy/tree/master/firmware/2950>
   - `MDRID295000` = English/international (what I used, bought in Europe)
   - `MDRID295002` = Chinese, `MDRID295003` = Japanese
   - The file I used: `4.3.1_UPG_english_enc_secureboot.0fdbd7f97b07f9feabed79f6189b6ac06e40a480.bin` (4,022,576 bytes)
   - **Check the download:** the long hex string in the filename is the file's SHA-1. In PowerShell: `Get-FileHash <file> -Algorithm SHA1` should match it. A tiny file (1 KB) means a failed download.

### Gotcha 1: the XM5 repo bundles the wrong `msvcr110.dll`

`yusen.exe` is **32-bit**, but the `msvcr110.dll` in that repo is **64-bit**. The tool exits immediately with no output (exit code `0xC000007B`, "invalid image format"). Fix it in either of these ways:

- **Easy:** install the official **Visual C++ Redistributable for Visual Studio 2012 Update 4, x86** from Microsoft, then **delete** the bundled `msvcr110.dll` from the tool folder.
- **No install:** extract the x86 `msvcr110.dll` from Microsoft's `vcredist_x86.exe` and put it next to `yusen.exe`. Check that it's signed by Microsoft Corporation.

### Gotcha 2: "LinkBuds S Manager" (pdiggitydogg) is broken

The GitHub tool *Sony_Linkbuds-S_Manager* (`LinkBudsManager.exe`) is an AutoHotkey GUI wrapped around this same `yusen.exe`. Its release is missing the embedded files: it extracts **0-byte** `yusen.exe`, `hidapi.dll` and `config.ini`, and then errors with *"%1 is not a valid Win32 application"* and *"This value of type String has no property named StdOut"*. Use `yusen.exe` directly as described below. (I didn't test whether dropping working files next to the GUI fixes it.)

---

## Setup

Make a folder (e.g. `C:\LinkBudsFlash\tool`) containing:

```
yusen.exe
hidapi.dll
msvcr110.dll        <- 32-bit (x86) version, see Gotcha 1
config.ini
firmware\fw431_en.bin   <- renamed firmware file (short name, no spaces)
```

`config.ini` for the LinkBuds S:

```ini
VID=0x054C
PID=0x0DF4
WAIT_TIME=10
TIMEOUT=5000
HASH_ONOFF=1
MODEL=3
TIMEOUT_HELO2=1000
RETRY_NUM_HELO2=0
```

- `PID=0x0DF4` is the LinkBuds S case. Check yours in Device Manager. It shows up as **"LinkBuds S"**, VID `054C`, PID `0DF4`.
- `MODEL=3`: the tool lists its models in the order HDX-2948, HDX-2953, HDX-2950, so the 3rd is the LinkBuds S. All read and flash commands worked with this.

Open a Command Prompt **in that folder** for the commands below.

---

## Step by step

### 1. Check the connection (read-only)

Put the earbud(s) in the **genuine Sony case**, close the lid, and plug the case into the PC.

```
yusen.exe devinfo                 (should list VID=054c PID=0df4 "Sony" "LinkBuds S")
yusen.exe helo                    (HELO to left/right = OK for each earbud present)
yusen.exe get mainver all         (firmware: Ver 0431 = 4.3.1)
yusen.exe get cradlever           (case firmware, mine was Ver 01.00)
yusen.exe get mainbatinfo all     (battery info per earbud)
```

An empty slot just times out after a few retries ("response timeout ... NG"). That's normal.

### 2. Flash only the odd earbud

Before you start:
- PC on mains power, sleep disabled.
- **Only the earbud you're flashing in the case**, lid **closed**.
- Don't touch the case or cable until it's done.

```
yusen.exe update left firmware\fw431_en.bin
```

(Use `right` for a right earbud.) My run took about **4 min 50 s**. Expected output ends with:

```
Info: transfer completed!
Info: verify data completed!
NOTE: LEFT target is executing firmware update now. Please wait until update completed.
```

**Leave it plugged in with the lid closed for 10 minutes.** The earbud installs the image internally.

### 3. Wake it and confirm

After 10 minutes, `get mainver left` **timed out** for me. Don't panic. **Open and close the lid 2–3 times** to wake the earbud, then:

```
yusen.exe get mainver left        (Ver 0431)
yusen.exe get mainbatinfo left
```

### 4. Sony initialize with the new pair

1. Put the partner earbud back in. Opening the lid may still show the **3 orange flashes**. That's fine.
2. With the lid **open**, press and hold the button on the back of the case for **about 15 seconds**.
3. What I saw: flashing stops, then slow orange blinking, then **4 green flashes** (initialization complete). Before the reflash it never reached the green flashes.
4. Opening the lid now gives **solid orange** and no fault.

### 5. Pair to your phone

1. Delete/forget **LinkBuds S** in your phone's Bluetooth settings, and in Sony | Sound Connect.
2. Take **both** earbuds out of the case. After an initialize they go into pairing mode.
3. Select **LinkBuds S** on the phone. Both sides should play, and Sound Connect should show 4.3.1.

---

## Using the tool in general (other firmware versions, other targets)

Steps 1–5 above are what I actually did. This section is the general recipe. Anything marked **untested** I didn't try myself.

### Command reference

| Command | What it does | Risk |
|---|---|---|
| `yusen.exe help` | Lists every command | none |
| `yusen.exe devinfo` | Lists HID devices (find VID/PID) | none |
| `yusen.exe helo` | Checks that the case can reach each earbud | none |
| `yusen.exe get mainver <left\|right\|all>` | Earbud firmware (`Ver 0431` = 4.3.1) | none |
| `yusen.exe get cradlever` | Case firmware | none |
| `yusen.exe get mainbatinfo <left\|right\|all>` | Earbud battery details | none |
| `yusen.exe get batvol` / `get batth` / `get coverstatus` | Case battery voltage / temperature / lid open or closed | none |
| `yusen.exe update left <file.bin>` | Flash the left earbud only | **can brick** |
| `yusen.exe update right <file.bin>` | Flash the right earbud only | **can brick** |
| `yusen.exe update dual <file.bin>` | Flash both earbuds at once | **can brick** |
| `yusen.exe sysreset <left\|right\|all>` | Reboot earbud(s) | low (untested) |

The `get` commands only read. Run them as often as you like. Leave the rest of what `help` shows alone (test mode, cradle test, `set vchg`, `flashwrite`, `pwbid`, `gwrite`, `cradleship`, raw `cmd`). Those write to the case or earbud.

### Flashing a different firmware version (including downgrades)

The firmware files are official Sony images, mirrored at:

**<https://github.com/lzghzr/MDR_Proxy/tree/master/firmware/2950>** (2950 = LinkBuds S / WF-LS900N)

Inside are one folder per region. Each holds every version Sony shipped:

| Folder | Region | Versions available (at time of writing) |
|---|---|---|
| `MDRID295000` | English / international (EU, US, …) | 2.0.2, 2.1.3, 3.0.5, 4.0.0, 4.1.0, 4.2.1, 4.3.1 |
| `MDRID295002` | Chinese | 2.0.2, 2.1.3, 3.0.5, 4.0.0, 4.1.0, 4.2.1, 4.3.1 |
| `MDRID295003` | Japanese | 2.0.2, 2.1.3, 3.0.5, 4.0.0, 4.1.0, 4.2.1, 4.3.1 |

Files are named `<version>_UPG_<language>_enc_secureboot.<sha1>.bin`. `MDRID295000` also has two files named `UPG_1.0.9_except_enc…` and `UPG_1.1.0_except_enc…`. I don't know what those are (they may be from the earliest releases, or for something else). **Don't flash them.**

To flash a version:
1. Download the `.bin` from the folder for **your region**. On GitHub, open the file and use "Download raw file". Don't save the web page.
2. Check it: `Get-FileHash <file> -Algorithm SHA1` (PowerShell) must match the hex string in the filename. The size should be several MB.
3. Copy it into `firmware\` with a short name, e.g. `firmware\fw421_en.bin`.
4. Run `yusen.exe update <left|right|dual> firmware\fw421_en.bin`, then wait 10 minutes, wake the earbud with the lid, and check with `get mainver`.

Notes:
- **Downgrading:** the tool doesn't block it, and the LinkBuds Manager author says it works "up or down". I only flashed 4.3.1 over 4.3.1, so downgrades are **untested** by me.
- **Matching a pair:** both earbuds should end on the **same version and region**. If you're matching a replacement earbud to an existing one, flash the replacement to whatever `get mainver` says the other one is on, and leave the good one alone.
- **Earbuds on very different versions:** flash them one at a time (`left`, then `right`) rather than `dual`. The XM5 updater's README recommends this too.
- **Getting newer versions into the app:** after flashing, Sony | Sound Connect can still offer official updates over Bluetooth as usual.

### Other Sony models (untested)

`yusen.exe` v0.13 lists three supported models: **HDX-2948, HDX-2953, HDX-2950**. The number is Sony's service ID, which is also the folder name in MDR_Proxy's `firmware/` directory. The MDR_Proxy README has a table mapping model names to service IDs.

- **LinkBuds S (WF-LS900N) = 2950**: tested, this guide.
- **WF-1000XM5:** the MKobra repo uses the same `yusen.exe` with `PID=0x0E63`, `MODEL=3`, and its firmware is in `firmware/2963/MDRID296300`. See that repo's README.
- **WF-1000XM4:** the original audiospare.com updater uses this tool. Check their instructions.
- **Anything else:** find the case's PID first, then compare with the models above. If your model isn't one the tool or an existing updater covers, don't guess. The wrong firmware for a model can brick it.

To find your case's VID/PID, plug in the case and either run `yusen.exe devinfo` and look for the "Sony" entry, or run this in PowerShell:

```powershell
Get-PnpDevice -PresentOnly | Where-Object InstanceId -match 'VID_054C' | Select FriendlyName, InstanceId
```

Then set `PID=0x....` in `config.ini` accordingly.

### Troubleshooting

| Problem | Fix |
|---|---|
| Nothing printed at all, exit code `0xC000007B` | Wrong (64-bit) `msvcr110.dll`. See Gotcha 1. |
| "msvcr110.dll is missing" | Install the VC++ 2012 x86 redistributable, or put the x86 DLL next to `yusen.exe`. |
| `unable to open device VID:054c PID:0df4` | The case isn't detected. Use a data cable and the **genuine** case, check the PID, and make sure only one case is plugged in. |
| `response timeout` on one side | Empty slot, or a sleeping earbud. Reseat it, and open and close the lid 2–3 times. |
| Earbud doesn't answer right after flashing | Normal. Wait 10 min, then open and close the lid to wake it. |
| Update fails partway | Don't unplug. Wake the earbud (lid open and close) and retry the same `update` command. The XM5 README also suggests holding the case button while opening and closing the lid 15–20 times to get a stable connection. |

---

## LED cheat sheet (genuine case, plugged in to USB)

| LED | What it meant for me |
|---|---|
| Solid orange | Case charging. Normal. |
| 3 orange flashes, repeating, on lid open | The two earbuds rejected each other as a pair. Not a battery or charging fault, in my case. |
| Dark, then slow orange blink, then solid orange, then back to 3 flashes | Initialize **failed** (before the reflash). |
| Dark, then slow orange blink, then **4 green flashes** | Initialize **completed** (after the reflash). |

---

## Other things worth knowing

- **Don't flash a different region to "fix" pairing.** The region is stored on the earbud, and flashing doesn't change it. Use the folder that matches where your earbuds were sold. The earbud accepting and verifying the image is a decent sign you picked the right one.
- `yusen.exe help` lists more commands (`sysreset`, `etm`, cradle test mode, charge-voltage settings, gauge writes, ship mode, raw `cmd`). Some of them **write to the case or earbud flash**. I only used `devinfo`, `helo`, `get ...` and `update`. Avoid the others unless you know what they do.
- `get mainbatinfo` "Charger State" values I saw: `0` = charging paused (seen during thermal pauses), `2` = charging, `4` = full/not charging. My interpretation, not documented.
- The MDR_Proxy method (patched Sound Connect app plus a proxy) needs **both earbuds connected over Bluetooth**, so it can't help when one earbud won't connect. The USB route can target a single earbud.

---

## Follow-up: the "new" earbud turned out to have a worn battery

Pairing worked, but over the following week the swapped-in left earbud showed problems. It's worth checking for this before you call a used single earbud a success.

### Symptoms in daily use

- After a full overnight charge, the app showed **left 68% / right 100%**.
- The left **died after about 2 h 20 min** of listening, while the right was still at 43%. That's roughly **55–60 % of the right's runtime**.
- The left's percentage **jumped up after resting** (14% to 30% after sitting powered off), then it **shut off early** under load. A quick jump back up after resting and an early shutdown under load are the classic signs of a cell with high internal resistance.
- More dropouts on the left in busy wireless areas. Switching Sound Connect to *Priority on stable connection* (AAC instead of LDAC) helped with the connection, but not the battery.
- The case seemed to drain faster, because it kept trickle-charging the left.

### How I measured it

I logged `yusen.exe get mainbatinfo all` every 60 s while both earbuds charged from empty in the genuine case, plugged into USB. It's a read-only command. The full instructions for doing this yourself are in **[Analyse it yourself](#analyse-it-yourself-no-ai-needed)** below.

### What the data showed (left = worn, right = healthy)

| | Worn left | Healthy right |
|---|---|---|
| Voltage at ~15% charge | 4.09–4.16 V, rising ~78 mV/min | right at ~40%: 4.08–4.11 V, ~35 mV/min |
| Voltage when it reported "full" | **~4.40 V** | ~4.25 V |
| Temperature while charging | **26 → 44 °C**, kept rising | 27 → 33 °C peak, then cooled |
| Charger behaviour near the end | **on/off cycling** (state 2 to 0 to 2) every time it hit ~44 °C | clean stop, state 4, about 55 min after plugging in |
| Voltage drop when charging pauses | **~200 mV** (4.34 to 4.13 V) | ~40 mV (4.25 to 4.21 V) |
| FG SOC vs UI SOC | 89% vs 60% mid-charge (way apart) | 81% vs 100% (stable mapping) |
| After app showed 100% | **still charging at 44 °C** | done, 29 °C |

The voltage drop when charging pauses is the clearest number. It's caused by internal resistance, and the left's is **about 5× the right's**. That one cause explains the rest: it heats up while charging, reads a high voltage while charging, hits "full" early with less energy stored, its voltage collapses under load (early shutdown), and it never cleanly finishes charging.

### Conclusion

- **This is battery wear (hardware). Firmware, initialize and gauge calibration can't fix it.** I flashed it, initialized it and ran a full empty-to-full calibration cycle. The pattern stayed the same.
- The `set vchg` (charge voltage) command doesn't fix a worn cell either, and it writes to the case. I didn't use it.
- The real fixes: a **new cell** (glued shell, so careful DIY or a repair shop), or **another single earbud** flashed with the method above.
- **When buying a used single earbud, ask about battery health/runtime.** Single earbuds are cheap partly because their batteries are often tired.
- Until it's replaced: short sessions only, don't charge it unattended or overnight, take it out once it shows 100%, and stop using it if the shell looks swollen or split.

### Analyse it yourself (no AI needed)

You don't need any special software for this. You need the tool from above, a spreadsheet (Excel, LibreOffice or Google Sheets), and about an hour and a half.

The idea is to **compare the two earbuds against each other while they charge side by side**. You don't need to know the "correct" values, because the healthy earbud is your reference. If one bud behaves very differently from its partner, that bud has the problem.

#### Step 1: Understand one reading

Run this once with both earbuds in the plugged-in case:

```
yusen.exe get mainbatinfo all
```

Example output (my two earbuds partway through charging):

```
GET_MAIN_BATTERY_INFO (LEFT): OK CAPACITY: 89(FG SOC: 89,UI SOC: 60),BattaryVoltage: 4335,ThermistorTemperature: 43.5,Charger State: 2,Charge current: 18,DMP: 0
GET_MAIN_BATTERY_INFO (RIGHT): OK CAPACITY: 100(FG SOC: 81,UI SOC: 100),BattaryVoltage: 4250,ThermistorTemperature: 31.3,Charger State: 2,Charge current: 18,DMP: 0
```

| Field | Meaning | Useful? |
|---|---|---|
| `BattaryVoltage` | Battery voltage in mV (Sony's typo) | **Yes**, the most useful field |
| `ThermistorTemperature` | Battery temperature in °C | **Yes** |
| `Charger State` | `2` = charging, `4` = full/stopped, `0` = paused (my interpretation) | **Yes** |
| `UI SOC` | The % shown in the app | Yes |
| `FG SOC` | The raw % from the battery gauge chip | Only compare it with UI SOC |
| `CAPACITY` | Seems to follow FG SOC (or 100 once full) | Not much |
| `Charge current` | Always showed 18 for me, so probably a setting, not a measurement | No |
| `DMP` | Unknown, was always 0 (once 1) | No |

#### Step 2: Log a full charge

1. Use both earbuds until they're **both nearly empty**. Note roughly when each one died, because runtime is evidence too.
2. Put both in the **genuine** case, close the lid, and plug the case into the PC.
3. **Keep the PC awake and plugged into mains** (Windows Settings, then Power: set "turn off screen" and "sleep" to *Never* for now). If the PC sleeps, logging stops and USB power to the case may be cut.
4. Save this as `log-charge.ps1` **in the same folder as `yusen.exe`**:

```powershell
# Logs both earbuds once a minute to charge-log.csv. Read-only. Stop with Ctrl+C.
Set-Location $PSScriptRoot
"time,side,ui_soc,fg_soc,voltage_mv,temp_c,state" | Set-Content charge-log.csv
while ($true) {
  $out = (& .\yusen.exe get mainbatinfo all) -join "`n"
  foreach ($side in 'LEFT','RIGHT') {
    if ($out -match "\($side\): OK.*?FG SOC: (\d+),UI SOC: (\d+)\),BattaryVoltage: (\d+),ThermistorTemperature: ([\d.]+),Charger State: (\d+)") {
      "$(Get-Date -Format 'HH:mm:ss'),$side,$($Matches[2]),$($Matches[1]),$($Matches[3]),$($Matches[4]),$($Matches[5])" |
        Add-Content charge-log.csv
    }
  }
  Start-Sleep 60
}
```

5. Run it from a PowerShell window in that folder:

```
powershell -ExecutionPolicy Bypass -File .\log-charge.ps1
```

6. **Don't open the lid** while it runs. Stop it with **Ctrl+C** once both earbuds show state `4`, or after about 2 hours.
7. **Safety:** if either earbud goes above **45 °C**, stop and take it out.

No PowerShell? Run `yusen.exe get mainbatinfo all` by hand every 5 minutes and write the numbers down. That works too, just with fewer data points.

#### Step 3: Make two charts

Open `charge-log.csv` in your spreadsheet. Filter or sort by `side` to get a LEFT and a RIGHT column for each value, then make line charts with time on the X axis:

1. **Temperature (LEFT and RIGHT)**
2. **Voltage (LEFT and RIGHT)**

A healthy pair gives two lines that roughly track each other. A worn bud stands out clearly.

#### Step 4: Check these five signs

Compare the suspect earbud with its partner:

| # | Check | Healthy (both look like this) | Worn battery |
|---|---|---|---|
| 1 | **Peak temperature** while charging | Both similar, mine peaked ~33 °C | Several °C hotter than the partner; mine reached ~44 °C |
| 2 | **Voltage at the same UI %** early in the charge | Similar | Clearly higher (100+ mV) even at a *lower* % |
| 3 | **Finishing**: does it reach state `4`? | Reaches `4` and stays there | Stays on `2` much longer, or flips `2 → 0 → 2` repeatedly |
| 4 | **Voltage drop when charging stops** (see below) | Small, mine ~40 mV | Large, mine ~200 mV |
| 5 | **Runtime** from a full charge (from step 2.1) | Both die close together | Dies well before the partner |

**How to measure #4:** find a row where the state changes from `2` to `0` or `4` (charging stops). Subtract the voltage in that row from the voltage in the row just before it. That drop comes from the battery's internal resistance, and a worn cell drops much more. Example from my log (worn earbud): `4337 mV (state 2)` followed by `4136 mV (state 0)` gives a **201 mV** drop.

#### Step 5: Decide

- **Three or more signs point at one earbud:** its battery is worn. Firmware, initialize or calibration won't fix it. Replace the cell or the earbud.
- **One sign, or only borderline differences:** do a full calibration cycle (run both to empty, charge uninterrupted to full), then test again. Gauges can be off right after a flash or reset.
- **Both earbuds behave the same, but battery life is short overall:** check your settings (LDAC, DSEE Extreme and noise canceling all use more power), or both batteries are simply ageing.

> These limits come from comparing **one** worn and **one** healthy earbud. They're not Sony specifications, so treat them as guidance. The side-by-side comparison with the partner earbud matters more than any exact number.

## Credits

- `yusen.exe` / `hidapi.dll`: third-party Sony HID service tooling, as redistributed in MKobra's **WF-1000XM5-firmware-updater** (originally from the audiospare.com WF-1000XM4 updater).
- Firmware: official Sony images mirrored at **lzghzr/MDR_Proxy**.
- MrWalkman's MDR Proxy guide and comments, which pointed me to the USB-C route.
