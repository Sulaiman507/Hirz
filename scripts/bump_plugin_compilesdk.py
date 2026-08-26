#!/usr/bin/env python3
"""رفع compileSdk لموديولات plugins في pub cache بعد pub get.

Bump compileSdk of plugin android modules inside the pub cache after pub get.
جراحي: نعدّل فقط الموديولات التي compileSdk فيها أقل من 34.
Surgical: only touch modules whose compileSdk is below 34.
"""
import glob
import os
import re

PUB_CACHE = os.environ.get(
    'PUB_CACHE', os.path.expanduser('~/.pub-cache')
)
FLOOR = 36  # متطلب androidx الحديث (fragment 1.7+ يتطلب 34+) / modern androidx requires 34+


def patch_module(build_gradle_path: str) -> None:
    with open(build_gradle_path, encoding='utf-8') as f:
        content = f.read()
    original = content

    def bump(match: re.Match) -> str:
        value = int(match.group(2))
        if value < FLOOR:
            return f'{match.group(1)}{FLOOR}'
        return match.group(0)

    content = re.sub(
        r'(compileSdk(?:Version)?\s*=?\s*)(\d+)', bump, content,
    )

    if content != original:
        with open(build_gradle_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('bumped:', build_gradle_path)


def main() -> None:
    patterns = [
        os.path.join(PUB_CACHE, 'hosted', 'pub.dartlang.org',
                     '*', 'android', 'build.gradle'),
        os.path.join(PUB_CACHE, 'hosted', 'pub.dev',
                     '*', 'android', 'build.gradle'),
        os.path.join(PUB_CACHE, 'git', '*', '*', 'android', 'build.gradle'),
    ]
    total = 0
    for pattern in patterns:
        for path in glob.glob(pattern):
            patch_module(path)
            total += 1
    print(f'scanned {total} plugin build.gradle files')


if __name__ == '__main__':
    main()
