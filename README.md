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
- `get mainbatinfo` "Charger State" values I saw: `2` = charging, `4` = full/not charging. My interpretation, not documented.
- The MDR_Proxy method (patched Sound Connect app plus a proxy) needs **both earbuds connected over Bluetooth**, so it can't help when one earbud won't connect. The USB route can target a single earbud.

## Credits

- `yusen.exe` / `hidapi.dll`: third-party Sony HID service tooling, as redistributed in MKobra's **WF-1000XM5-firmware-updater** (originally from the audiospare.com WF-1000XM4 updater).
- Firmware: official Sony images mirrored at **lzghzr/MDR_Proxy**.
- MrWalkman's MDR Proxy guide and comments, which pointed me to the USB-C route.
