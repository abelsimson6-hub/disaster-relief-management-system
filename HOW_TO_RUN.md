# How to Run the Disaster Relief Management System App

## Quick Start

### 1. Make sure dependencies are installed
```bash
flutter pub get
```

### 2. Start the Django Backend Server (Required for login/registration)

**Open a terminal and run:**
```bash
cd DRMS
python manage.py runserver
```

You should see:
```
Starting development server at http://127.0.0.1:8000/
```

**Important:** Keep this terminal window open while using the app!

### 3. Run the Flutter App

**Open a new terminal and run one of the following:**

#### For Web:
```bash
flutter run -d chrome
```

#### For iOS Simulator (Mac only):
```bash
open -a Simulator
flutter run -d ios
```

#### For Android Emulator:
First, start an Android emulator, then:
```bash
flutter run -d android
```

#### For Desktop:
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

### 4. Check Available Devices

To see all available devices:
```bash
flutter devices
```

## Troubleshooting

### "App not running" Issues

1. **Backend server not running**
   - Make sure Django server is running on port 8000
   - Test by visiting: `http://localhost:8000/api/test/`
   - Should return: `{"message": "API working!"}`

2. **Port already in use**
   - If port 8000 is busy, use a different port:
     ```bash
     python manage.py runserver 8001
     ```
   - Then update `lib/services/api_service.dart` to use port 8001

3. **Flutter dependencies not installed**
   ```bash
   flutter pub get
   flutter clean
   flutter pub get
   ```

4. **Compilation errors**
   ```bash
   flutter analyze
   flutter doctor
   ```

### Common Errors

- **"Cannot connect to server"** → Backend not running (see step 2)
- **"No devices found"** → Start an emulator/simulator first
- **"Build failed"** → Run `flutter clean && flutter pub get`

## Development Tips

- Use **Hot Reload** (press `r` in the terminal where Flutter is running) to see changes instantly
- Use **Hot Restart** (press `R`) to fully restart the app
- Check the Flutter console for error messages
- For web, open browser DevTools (F12) to see network requests and errors

## Testing Login/Registration

1. Make sure backend is running (step 2)
2. Run the Flutter app
3. Try to register a new user
4. Then login with those credentials

If you see connection errors, the backend server is likely not running!

