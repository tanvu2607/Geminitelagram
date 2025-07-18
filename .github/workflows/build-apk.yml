name: Build Android APK

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Build APK
        run: ./gradlew assembleRelease

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release.apk
          path: app/build/outputs/apk/release/app-release.apk
