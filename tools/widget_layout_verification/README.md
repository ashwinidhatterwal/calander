# Native widget verification without Flutter

`python tools/verify_widget_layouts.py --gradle /path/to/gradle`

Requires JDK 17, Gradle 8.11.1, Android platform 35 and build-tools 35.0.0.
Set JAVA_HOME and ANDROID_HOME to the installed JDK and SDK. This runner copies
current widget resources, the shared bundled font and WidgetLayoutTest into a
fresh temporary Android module. It compiles and executes the actual Android 9
and 15 tests, including all 72 size/language/font-scale/layout combinations.
It does not maintain a second copy of the test or the widget layouts.

Optional `--preview-dir /path/to/previews` saves representative native renders.
The app's normal GitHub workflow still runs all native tests and APK packaging;
this focused verifier does not replace the full release pipeline.
