#!/usr/bin/env python3
import sys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/android-build.yml"
APP_GRADLE = ROOT / "app/build.gradle.kts"


def read_logs(dir_path: Path) -> str:
    chunks = []
    for p in dir_path.rglob("*.txt"):
        try:
            chunks.append(p.read_text(errors="ignore"))
        except Exception:
            pass
    return "\n\n".join(chunks)


def apply_workflow_fix_android_sdk_root(log_text: str) -> bool:
    # If sdkmanager cannot be found or class not found, ensure we install commandline-tools and export ANDROID_SDK_ROOT
    if "Could not find or load main class com.android.sdklib.tool.sdkmanager.SdkManagerCli" in log_text:
        content = WORKFLOW.read_text()
        if "commandlinetools-linux" not in content or "cmdline-tools/latest" not in content:
            # Insert our manual install block before Download Gradle
            new_content = content.replace(
                "- name: Download Gradle",
                "- name: Setup Android SDK (ai-fix)\n        shell: bash\n        run: |\n          set -euo pipefail\n          ANDROID_SDK_ROOT=\"$HOME/android-sdk\"\n          echo \"ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT\" >> $GITHUB_ENV\n          mkdir -p \"$ANDROID_SDK_ROOT\"\n          curl -fo sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip\n          mkdir -p \"$ANDROID_SDK_ROOT/cmdline-tools\"\n          unzip -q sdk.zip -d \"$ANDROID_SDK_ROOT/cmdline-tools\"\n          mv \"$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools\" \"$ANDROID_SDK_ROOT/cmdline-tools/latest\"\n          yes | \"$ANDROID_SDK_ROOT\"/cmdline-tools/latest/bin/sdkmanager --sdk_root=\"$ANDROID_SDK_ROOT\" --licenses\n          \"$ANDROID_SDK_ROOT\"/cmdline-tools/latest/bin/sdkmanager --sdk_root=\"$ANDROID_SDK_ROOT\" \\\n            \"platform-tools\" \\\n            \"platforms;android-34\" \\\n            \"build-tools;34.0.0\"\n\n      - name: Download Gradle"
            )
            WORKFLOW.write_text(new_content)
            return True
    return False


def apply_gradle_fix_quote_model(log_text: str) -> bool:
    # If Gradle fails on buildConfigField quoting, ensure double-escaped quotes
    if "buildConfigField" in log_text and "GEMINI_MODEL" in log_text:
        content = APP_GRADLE.read_text()
        fixed = re.sub(
            r'buildConfigField\((\s*)"String",(\s*)"GEMINI_MODEL",(\s*)[^\)]*\)',
            'buildConfigField("String", "GEMINI_MODEL", "\\\"gemini-2.5-flash\\\"")',
            content,
            flags=re.M,
        )
        if fixed != content:
            APP_GRADLE.write_text(fixed)
            return True
    return False


def main():
    if len(sys.argv) < 2:
        print("usage: ai_fix.py <logs_dir>")
        return 1
    logs_dir = Path(sys.argv[1])
    log_text = read_logs(logs_dir)

    changed = False
    changed |= apply_workflow_fix_android_sdk_root(log_text)
    changed |= apply_gradle_fix_quote_model(log_text)

    if changed:
        # create a commit
        import subprocess
        subprocess.run(["git", "config", "user.name", "ai-fix-bot"], check=False)
        subprocess.run(["git", "config", "user.email", "ai-fix-bot@users.noreply.github.com"], check=False)
        subprocess.run(["git", "add", str(WORKFLOW), str(APP_GRADLE)], check=False)
        subprocess.run(["git", "commit", "-m", "ci(ai-fix): apply automated fixes"], check=False)
        print("Applied fixes and committed.")
        return 0
    else:
        print("No known fixes applied.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())