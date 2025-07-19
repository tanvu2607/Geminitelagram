# Flutter APK Builder

This repository contains a simple Flutter application and a GitHub Actions workflow to automatically build and sign the APK.

## Setup

1.  **Create a GitHub Secret:** Create a GitHub secret named `RELEASE_KEYSTORE_BASE64` containing the base64 encoded content of your release keystore file.  Ensure your keystore has the necessary permissions for release builds.
2. **Commit your code:** Commit and push the code to your GitHub repository.

## Workflow

The GitHub Actions workflow will automatically trigger on push to the `main` branch and perform the following steps:

1.  Checkout the code.
2.  Set up JDK 11.
3.  Install Flutter.
4.  Get Flutter dependencies.
5.  Create `local.properties` file.
6.  Decode the base64 encoded keystore.
7.  Build the release APK.
8.  Upload the APK as an artifact.

You can download the built APK from the Actions tab after a successful run.