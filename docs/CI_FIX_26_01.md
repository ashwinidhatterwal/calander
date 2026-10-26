# Build 26 CI correction - package imports

GitHub QA run 40262335057, commit 7ae5d32d5de3414399969ee23f671b54d228f58e,
failed in flutter analyze with three avoid_relative_lib_imports findings in
tool/verify_festival_rules.dart. The verifier imported production libraries
using ../lib/domain paths. Those imports now use package:hindu_calendar/domain.
No calculation, app UI, PDF rendering, version or signing changes are involved.

Validation: reproduced all three lint findings locally with the actual Dart
avoid_relative_lib_imports rule enabled. Corrected file: no issues. The corrected
verification tool still passes all 1,485 calculation checks. Source checks pass.
The failed GitHub run stopped before Flutter tests/native checks/build; those
stages still require a new run on the corrected commit. Rerunning the old run
uses the old imports. Version code remains 26.
