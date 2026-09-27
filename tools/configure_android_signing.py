#!/usr/bin/env python3
from pathlib import Path

path = Path('android/app/build.gradle.kts')
text = path.read_text(encoding='utf-8')

imports = 'import java.util.Properties\nimport java.io.FileInputStream\n\n'
if 'import java.util.Properties' not in text:
    text = imports + text

props = '''val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
if 'val keystoreProperties = Properties()' not in text:
    text = text.replace('android {', props + 'android {', 1)

signing = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

'''
if 'create("release")' not in text:
    marker = '    buildTypes {'
    if marker not in text:
        raise SystemExit('Unable to locate buildTypes block in generated Flutter Android project')
    text = text.replace(marker, signing + marker, 1)

old = 'signingConfig = signingConfigs.getByName("debug")'
new = 'signingConfig = signingConfigs.getByName("release")'
if old in text:
    text = text.replace(old, new, 1)
elif new not in text:
    raise SystemExit('Unable to locate release signingConfig line')

path.write_text(text, encoding='utf-8')
