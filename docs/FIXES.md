# Quick system fixes

This document contains all the fixes I've made on my various systems; some will work, others will break yours; be careful.

## Linux

### Panel Self Refresh` (PSR) issues on Intel graphic card
> source: https://bugzilla.redhat.com/show_bug.cgi?id=2055360

```bash
cat <<EOF | sudo tee /etc/modprobe.d/i915.conf
# Disable Panel Self Refresh (PSR) feature on i915
# See https://bugzilla.redhat.com/show_bug.cgi?id=2055360
options i915 enable_psr=0
EOF
```

> tags: freeze,gnome,intel,intel-graphic,i915
