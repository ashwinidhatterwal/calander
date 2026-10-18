#!/usr/bin/env python3
"""Run the actual Android widget layout tests without installing Flutter.

Requires JDK 17+, Gradle 8.11.1, Android platform 35 and build-tools 35.0.0.
ANDROID_HOME/ANDROID_SDK_ROOT and JAVA_HOME use their normal SDK/JDK meanings.
Extra arguments are forwarded to Gradle (for example explicit proxy properties).
"""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gradle', default=shutil.which('gradle'))
    parser.add_argument('--preview-dir', type=Path)
    args, extra = parser.parse_known_args()
    if not args.gradle:
        parser.error('Gradle not found; supply --gradle /absolute/path/to/gradle')
    repo = Path(__file__).resolve().parents[1]
    widget = repo / 'flutter_app/android_widget'
    with tempfile.TemporaryDirectory(prefix='calendar-widget-check-') as directory:
        project = Path(directory)
        shutil.copytree(repo / 'tools/widget_layout_verification', project,
                        dirs_exist_ok=True)
        shutil.copytree(widget / 'res', project / 'src/main/res')
        font_dir = project / 'src/main/res/font'
        font_dir.mkdir(exist_ok=True)
        shutil.copyfile(repo / 'flutter_app/assets/fonts/NotoSansDevanagari.ttf',
                        font_dir / 'calendar_widget_text.ttf')
        tests = project / 'src/test/kotlin/in/hinducalendar/hindu_calendar'
        tests.mkdir(parents=True)
        shutil.copyfile(widget / 'test/WidgetLayoutTest.kt',
                        tests / 'WidgetLayoutTest.kt')
        command = [str(Path(args.gradle).resolve()), '--no-daemon',
                   '--console=plain', 'testDebugUnitTest']
        if args.preview_dir:
            command.append('-Dcalendar.widget.preview.dir=' +
                           str(args.preview_dir.resolve()))
        result = subprocess.run(command + extra, cwd=project, env=os.environ)
        return result.returncode


if __name__ == '__main__':
    raise SystemExit(main())
