"""
Configures Android Gradle settings and AndroidManifest for Teddy AI APK build
"""
import os

def configure():
    # 1. Update AndroidManifest.xml
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()

        permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
"""
        if "android.permission.INTERNET" not in content:
            content = content.replace("<application", permissions + "\n    <application")
            with open(manifest_path, "w", encoding="utf-8") as f:
                f.write(content)
            print("Injected permissions into AndroidManifest.xml")

    # 2. Update build.gradle or build.gradle.kts
    kts_path = "android/app/build.gradle.kts"
    groovy_path = "android/app/build.gradle"

    if os.path.exists(kts_path):
        target = kts_path
        is_kts = True
    else:
        target = groovy_path
        is_kts = False

    if os.path.exists(target):
        with open(target, "r", encoding="utf-8") as f:
            lines = f.readlines()

        new_lines = []
        in_compile_options = False
        desugar_enabled = False
        has_dependencies = False

        for line in lines:
            if "compileOptions {" in line:
                in_compile_options = True
                new_lines.append(line)
                if is_kts:
                    new_lines.append("        isCoreLibraryDesugaringEnabled = true\n")
                else:
                    new_lines.append("        coreLibraryDesugaringEnabled true\n")
                desugar_enabled = True
                continue

            if in_compile_options and "}" in line:
                in_compile_options = False

            if "dependencies {" in line:
                has_dependencies = True
                new_lines.append(line)
                if is_kts:
                    new_lines.append('    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n')
                else:
                    new_lines.append('    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.0.4"\n')
                continue

            # Ensure minimum SDK is 21
            if "minSdk" in line:
                if is_kts:
                    new_lines.append("        minSdk = 21\n")
                else:
                    new_lines.append("        minSdk 21\n")
                continue

            new_lines.append(line)

        if not has_dependencies:
            if is_kts:
                new_lines.append('\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n')
            else:
                new_lines.append('\ndependencies {\n    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.0.4"\n}\n')

        with open(target, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print(f"Successfully configured desugaring in {target}")

if __name__ == "__main__":
    configure()
