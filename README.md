<p align="center">
  <img src="assets/raybridge-logo-nbg.png" alt="Raybridge" width="400">
</p>

## ⚠️ Development Status

Raybridge is currently in **active development**.

This project is a **work in progress** and should be considered **experimental**.  
Features, scripts, configuration formats, and deployment methods may change at any time.

Do **not** rely on Raybridge for:
- Critical safety
- Legal compliance
- Law enforcement or evidentiary use
- Production or unattended operation

Use at your own risk.  
Always verify results independently and understand the legal and technical implications of running cellular monitoring tools in your jurisdiction.


# Raybridge Script Bundle

This is a ready-to-copy bundle of the three Raybridge scripts plus templates for manual configuration.

## Contents
- scripts/
  - sync_captures.sh (downloads Rayhunter ZIP bundles: PCAP+QMDL)
  - make_dashboard.sh (generates a lightweight status dashboard)
  - heartbeat.sh (sends daily email status)
- templates/
  - msmtprc.template (SMTP config template for msmtp)
  - raybridge.env.template (set Orbic URL, email recipient, paths)
- docs/
  - MANUAL_INSTALL.md (step-by-step manual setup)

## What you must customize
1) `/etc/msmtprc` from `templates/msmtprc.template`
2) `/opt/raybridge/raybridge.env` from `templates/raybridge.env.template`

## Compatibility
- Rayhunter v0.9.0+ (uses `/api/qmdl-manifest` and `/api/zip/{name}`)
- Raspberry Pi OS Lite (32-bit)
