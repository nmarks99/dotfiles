# Snapper + snap-pac

## Setup (done)

Install:
```bash
sudo pacman -S snapper snap-pac
```

Enable timed snapshots
```bash
sudo snapper -c root create-config /
```

Enable timed snapshots
```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

---

## Commands

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

## Config File

/etc/snapper/configs/root

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

---

## Typical Workflow

### List snapshots
sudo snapper -c root list

### Inspect what changed
sudo snapper -c root status <id1>..<id2>

### Roll back change
sudo snapper -c root undochange <id1>..<id2>

---
