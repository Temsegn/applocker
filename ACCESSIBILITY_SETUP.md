# AppLock – Accessibility setup (required for locking apps)

For AppLock to **intercept when you open a locked app** and show the PIN/password screen, the **AppLock accessibility service** must be turned on and allowed to run.

## Steps (do these once)

### 1. Open Android Settings
- Go to **Settings → Accessibility** (or **Settings → Accessibility → Installed services** on some devices).

### 2. Enable AppLock’s accessibility service
- Find **AppLock** in the list.
- Turn the switch **ON**.
- If Android shows a warning, tap **Allow** / **OK**.

### 3. Optional but recommended
- **Battery / App launch:**  
  **Settings → Apps → AppLock → Battery** (or “App launch”)  
  - Set to **Unrestricted** or **Don’t optimize** so the system doesn’t kill the service.
- **Autostart (some brands):**  
  If your phone has “Autostart” or “Start in background”, enable it for **AppLock**.

### 4. After an app update
- If locking stops working after updating AppLock, go to **Settings → Accessibility**, turn **AppLock OFF**, then turn it **ON** again.

## How to check it’s working

1. In AppLock, lock an app (e.g. Chrome or Settings) with a PIN.
2. Press Home, then open that app from the launcher.
3. You should be taken to the home screen and then AppLock should open and show the PIN screen for that app.

If that does **not** happen:
- Confirm AppLock is **ON** under **Settings → Accessibility**.
- Disable battery optimization for AppLock (step 3 above).
- Restart the phone and try again.
- On some brands (Xiaomi, Oppo, Vivo, etc.), also allow **Autostart** and **Run in background** for AppLock.

## What AppLock uses accessibility for

- Detecting when a **locked** app is opened.
- Sending you to the home screen and opening AppLock so you can enter the PIN/password.
- It does **not** read or send your screen content; it only checks which app is in the foreground.
