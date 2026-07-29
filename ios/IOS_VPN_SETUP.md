# iOS VPN (Network Lockdown) — Apple Developer setup

Required once per App ID before Packet Tunnel works on a physical device.

## 1. Enable Network Extension capability

1. Sign in at [Apple Developer](https://developer.apple.com/account).
2. **Certificates, Identifiers & Profiles** → **Identifiers**.
3. Select App ID `com.example.militaryExam` (or create it).
4. Enable **Network Extensions**.
5. Under Network Extensions, check **Packet Tunnel Provider**.
6. Save.

## 2. Extension App ID

1. Create a second App ID: `com.example.militaryExam.PacketTunnel`.
2. Enable **Network Extensions** → **Packet Tunnel Provider**.
3. Save.

## 3. Provisioning profiles

Regenerate (or create) development/distribution profiles for:

- `com.example.militaryExam` (Runner)
- `com.example.militaryExam.PacketTunnel` (PacketTunnel extension)

Download and install, or use Xcode automatic signing with the same team (`Z443U3HP2C`).

## 4. Xcode verification

1. Open `ios/Runner.xcworkspace`.
2. Select **Runner** target → **Signing & Capabilities** → confirm **Network Extensions** / Packet Tunnel.
3. Select **PacketTunnel** target → same capability and valid provisioning profile.
4. Build **Runner** scheme on a physical iPhone (simulator does not support Packet Tunnel).

## 5. Runtime test

1. Open the app → security flow → VPN lockdown screen.
2. Tap **নেটওয়ার্ক লকডাউন চালু করুন**.
3. Allow the system VPN configuration prompt.
4. Settings → VPN should show **Military Exam Lockdown** connected.

Until step 1–3 are done, `saveToPreferences` / `startVPNTunnel` will fail and the app shows an error state.
