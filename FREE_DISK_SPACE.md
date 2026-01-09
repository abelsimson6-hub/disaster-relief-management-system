# Disk Space Issue - Fix Guide

## Problem
Your system is **96% full** (only 502MB free out of 228GB). This is preventing Flutter from compiling the app.

Error: `FileSystemException: writeFrom failed... (OS Error: No space left on device, errno = 28)`

## Quick Fixes

### 1. Clean Flutter Build Files (Already Done)
```bash
flutter clean
```

### 2. Clean Xcode DerivedData (Can free ~15GB!)
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```
⚠️ **Note**: This will delete Xcode's build cache. Xcode will rebuild these when needed.

### 3. Clean System Temporary Files
```bash
# Clean Flutter temp files
rm -rf /var/folders/*/T/flutter_tools.* 2>/dev/null

# Clean Dart temp files
rm -rf /tmp/dart* 2>/dev/null
```

### 4. Empty Trash
```bash
# From Finder: Empty Trash
# Or from terminal:
rm -rf ~/.Trash/*
```

### 5. Clean Flutter Pub Cache (Optional - Can free ~1.3GB)
**WARNING**: This will require re-downloading packages when you run `flutter pub get`
```bash
flutter pub cache clean
# Then run: flutter pub get
```

### 6. Clean Docker/Container Images (If you use Docker)
```bash
docker system prune -a --volumes
```

### 7. Check Large Files
Find large files taking up space:
```bash
# Find files larger than 1GB
find ~ -type f -size +1G -ls 2>/dev/null | head -20

# Find large directories
du -sh ~/* 2>/dev/null | sort -h | tail -20
```

### 8. Clean macOS System Files
```bash
# Clean system logs (may require sudo)
sudo rm -rf /private/var/log/*

# Clean old system files (use with caution)
# Only if you're sure you don't need them
```

## Recommended Steps (In Order)

1. **Empty Trash** (easiest, can free several GB)
2. **Clean Xcode DerivedData**: `rm -rf ~/Library/Developer/Xcode/DerivedData/*` (can free ~15GB)
3. **Clean Flutter temp files**: Already done with `flutter clean`
4. **Check Downloads folder** for large files you don't need
5. **Uninstall unused applications** from Applications folder

## After Freeing Space

Once you have more free space (aim for at least 2-3GB free):

1. Run the app again:
   ```bash
   flutter run -d chrome
   ```

2. Or use VS Code's launch configuration (F5)

## Check Available Space
```bash
df -h /
```

You should see more free space after cleaning.

## Minimum Space Requirements

- **At least 2-3GB free** for Flutter development
- **5GB+ recommended** for comfortable development
- Currently: **Only 502MB free** (96% full)

---

## Automatic Cleanup Script

Run this to clean common Flutter/Xcode build artifacts:

```bash
#!/bin/bash
echo "Cleaning Flutter build files..."
flutter clean

echo "Cleaning Xcode DerivedData (this may take a while)..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "Cleaning Flutter temp files..."
rm -rf /var/folders/*/T/flutter_tools.* 2>/dev/null

echo "Cleaning Dart temp files..."
rm -rf /tmp/dart* 2>/dev/null

echo "Done! Check disk space:"
df -h /
```

Save as `cleanup.sh`, make executable: `chmod +x cleanup.sh`, then run: `./cleanup.sh`

