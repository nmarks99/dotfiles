# Snapper + snap-pac (Arch Linux) Quick Guide

## Overview
This setup provides:
- Automatic snapshots on pacman transactions (via snap-pac)
- Optional timed snapshots (via snapper timeline)
- Ability to inspect and roll back filesystem changes

---

## Components

- snapper → snapshot management
- snap-pac → hooks into pacman (pre/post snapshots)
- btrfs → required filesystem

---

## Basic Setup (already done)

sudo pacman -S snapper snap-pac
sudo snapper -c root create-config /

---

## Key Commands

### List snapshots
sudo snapper -c root list

### Create manual snapshot
sudo snapper -c root create --description "desc"

### Compare snapshots
sudo snapper -c root status <pre>..<post>

### Show diff
sudo snapper -c root diff <pre>..<post>

### Undo changes
sudo snapper -c root undochange <pre>..<post>

---

## snap-pac (pacman integration)

Automatically creates:
- pre snapshot (before install/update)
- post snapshot (after)

Test:
sudo pacman -S nano
sudo snapper -c root list

---

## Timeline Snapshots (optional)

Enable:
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

---

## Config File

Edit:
sudo nano /etc/snapper/configs/root

### Important Options

Enable timeline:
TIMELINE_CREATE="yes"

Retention limits:
TIMELINE_LIMIT_HOURLY="1"
TIMELINE_LIMIT_DAILY="3"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_QUARTERLY="4"
TIMELINE_LIMIT_YEARLY="0"

Notes:
- Limits control how many snapshots are kept, not when they are created
- QUARTERLY is a retention tier, not a schedule

---

## How It Works

- snap-pac → protects against broken package installs
- timeline → protects against manual/system changes
- snapshots stored in:
  /.snapshots

---

## Typical Workflow

### After system change
sudo snapper -c root list

### Inspect what changed
sudo snapper -c root status <id1>..<id2>

### Roll back change
sudo snapper -c root undochange <id1>..<id2>

---

## Notes / Gotchas

- Works only on Btrfs
- Does not track bootloader/EFI (unless on Btrfs)
- Pacman state may need manual sync after rollback:
  sudo pacman -S <pkg>

---

## Summary

- snap-pac = package safety
- snapper timeline = system safety
- snapper undochange = recovery tool
