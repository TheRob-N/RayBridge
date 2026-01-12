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
