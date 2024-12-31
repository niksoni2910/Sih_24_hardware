# DeviceDNA 🧬

A Flutter application that creates a unique device identifier by combining:
- Device hardware information
- User's selfie
- ECC (Elliptic Curve Cryptography) keys

## Core Features

1. **Device Information Collection**
   - Gathers detailed hardware specs
   - Different parameters for Android/iOS

2. **Biometric Integration**
   - Front camera selfie capture
   - Image processing for verification

3. **Cryptographic Security**
   - ECC key pair generation
   - SHA-256 hashing for combined data

## Team Members


1. [Amir Zakaria](https://github.com/huntingcodes-001)
2. [Aishwarya Ravi](https://github.com/AishwaryaRavi07)
3. [Nikhil Soni](https://github.com/niksoni2910)
4. [Atharva Kshirsagar](https://github.com/pranavjanjani)
5. [Muhammad Sheikh](https://github.com/muhd360)
6. [Parth Agarwal](https://github.com/Aadit0122)

## Setup
```bash
flutter pub get
flutter run
```

## Dependencies
- device_info_plus
- image_picker
- crypto
- flutter/material.dart

## Usage
1. Launch app
2. Take selfie
3. View device info
4. Check verification details
5. Access key information
