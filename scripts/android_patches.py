#!/usr/bin/env python3
"""تعديلات أندرويد بعد flutter create في CI / Native Android patches after scaffold.

١) حقن الصلاحيات في AndroidManifest.xml (إشعارات + منبه دقيق + اهتزاز + اقلاع)
٢) نسخ ملفات الصوت إلى android/app/src/main/res/raw
٣) تمكين core library desugaring (مطلوب لمكتبة الإشعارات مع minSdk < 26)
٤) كتابة keep.xml لمنع shrinkResources من حذف الأصوات
"""
import os
import re
import shutil
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAFFOLD = os.path.join(ROOT, 'scaffold')

PERMISSIONS = (
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.USE_FULL_SCREEN_INTENT',
    'android.permission.SCHEDULE_EXACT_ALARM',
    'android.permission.USE_EXACT_ALARM',
    'android.permission.VIBRATE',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
)


def patch_manifest() -> None:
    path = os.path.join(SCAFFOLD, 'android/app/src/main/AndroidManifest.xml')
    with open(path, encoding='utf-8') as f:
        content = f.read()
    missing = [
        p for p in PERMISSIONS if f'android:name="{p}"' not in content
    ]
    if not missing:
        print('manifest: permissions already present')
        return
    block = ''.join(
        f'    <uses-permission android:name="{p}"/>\n' for p in missing
    )
    content = content.replace('<application', block + '    <application', 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('manifest: injected', len(missing), 'permissions')


def copy_audio() -> None:
    src_dir = os.path.join(ROOT, 'assets/audio')
    raw_dir = os.path.join(SCAFFOLD, 'android/app/src/main/res/raw')
    os.makedirs(raw_dir, exist_ok=True)
    for name in os.listdir(src_dir):
        if name.endswith('.mp3'):
            shutil.copy(os.path.join(src_dir, name), os.path.join(raw_dir, name))
            print('audio:', name, '-> res/raw')


def add_keep_xml() -> None:
    raw_dir = os.path.join(SCAFFOLD, 'android/app/src/main/res/raw')
    if not os.path.isdir(raw_dir):
        print('keep.xml: res/raw not found, skipping')
        return
    xml_dir = os.path.join(SCAFFOLD, 'android/app/src/main/res/xml')
    os.makedirs(xml_dir, exist_ok=True)
    path = os.path.join(xml_dir, 'keep.xml')
    keeps = []
    for name in os.listdir(raw_dir):
        if name.endswith('.mp3'):
            keeps.append(f'@raw/{name.replace(".mp3", "")}')
    if not keeps:
        print('keep.xml: no audio files found')
        return
    with open(path, 'w', encoding='utf-8') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n')
        f.write('<resources xmlns:tools="http://schemas.android.com/tools"\n')
        f.write(f'    tools:keep="{",".join(keeps)}"/>\n')
    print('keep.xml written with', len(keeps), 'entries')


DESUGAR_VERSION = '2.1.4'


def patch_root_subprojects_floor() -> None:
    """فرض حد أدنى compileSdk=36 على كل موديولات Android (بما فيها plugins).

    Force a compileSdk floor of 36 across all Android subprojects (plugins).
    """
    for candidate in (
        'android/build.gradle.kts',
        'android/build.gradle',
    ):
        path = os.path.join(SCAFFOLD, candidate)
        if not os.path.exists(path):
            print('root floor:', candidate, 'not found, skipping')
            continue
        with open(path, encoding='utf-8') as f:
            content = f.read()
        if 'COMPILE_SDK_FLOOR' in content:
            print('root floor: already applied')
            return
        kts = candidate.endswith('.kts')
        if kts:
            block = '''
// COMPILE_SDK_FLOOR: raise any subproject below the floor (plugins included)
// withId hook runs at plugin application time (safe after evaluation started)
subprojects {
    project.plugins.withId("com.android.library") {
        val androidExt = project.extensions.findByName("android")
            as? com.android.build.gradle.LibraryExtension
        if (androidExt != null && androidExt.compileSdk != null && androidExt.compileSdk!! < 36) {
            androidExt.compileSdk = 36
        }
    }
    project.plugins.withId("com.android.application") {
        val androidExt = project.extensions.findByName("android")
            as? com.android.build.gradle.internal.dsl.BaseAppModuleExtension
        if (androidExt != null && androidExt.compileSdk != null && androidExt.compileSdk!! < 36) {
            androidExt.compileSdk = 36
        }
    }
}
'''
        else:
            block = '''
// COMPILE_SDK_FLOOR: raise any subproject below the floor (plugins included)
subprojects { proj ->
    proj.afterEvaluate {
        if (proj.hasProperty("android")) {
            def androidExt = proj.android
            if (androidExt.compileSdkVersion != null) {
                def m = androidExt.compileSdkVersion =~ /(\\d+)$/
                if (m.find() && (m.group(1) as int) < 36) {
                    androidExt.compileSdkVersion 36
                }
            }
        }
    }
}
'''
        content += block
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('root floor: applied to', candidate)
        return
    # لا يوجد ملف root — أنشئ .kts بسيطاً مع الإعداد المطلوب
    # No root file — create a minimal .kts with the floor block
    path = os.path.join(SCAFFOLD, 'android/build.gradle.kts')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(
            '// COMPILE_SDK_FLOOR generated\n'
            'allprojects {\n'
            '    repositories {\n'
            '        google()\n'
            '        mavenCentral()\n'
            '    }\n'
            '}\n'
        )
        f.write('''
subprojects {
    project.plugins.withId("com.android.library") {
        val androidExt = project.extensions.findByName("android")
            as? com.android.build.gradle.LibraryExtension
        if (androidExt != null && androidExt.compileSdk != null && androidExt.compileSdk!! < 36) {
            androidExt.compileSdk = 36
        }
    }
}
''')
    print('root floor: created new build.gradle.kts')


def patch_gradle_desugaring() -> None:
    for candidate in (
        'android/app/build.gradle',
        'android/app/build.gradle.kts',
    ):
        path = os.path.join(SCAFFOLD, candidate)
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            content = f.read()
        # رفع compileSdk لمتطلبات geolocator/notifications
        # القالب يستخدم flutter.compileSdkVersion (رمز) → نستبدله برقم صريح 36
        new_content = re.sub(
            r'compileSdk\s*=\s*flutter\.compileSdkVersion',
            'compileSdk = 36',
            content,
        )
        new_content = re.sub(
            r'compileSdk\s*=\s*\d+',
            'compileSdk = 36',
            new_content,
        )
        new_content = re.sub(
            r'compileSdkVersion\s+\d+',
            'compileSdkVersion 36',
            new_content,
        )
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print('gradle: compileSdk bumped to 36 in', candidate)
        with open(path, encoding='utf-8') as f:
            content = f.read()
        if 'coreLibraryDesugaring' in content:
            print('gradle: desugaring already enabled')
            return
        kts = candidate.endswith('.kts')
        if 'compileOptions {' in content:
            if kts:
                content = content.replace(
                    'compileOptions {',
                    'compileOptions {\n        isCoreLibraryDesugaringEnabled = true',
                    1,
                )
                dep_line = (
                    '    coreLibraryDesugaring('
                    '"com.android.tools:desugar_jdk_libs:'
                    + DESUGAR_VERSION + '")\n'
                )
            else:
                content = content.replace(
                    'compileOptions {',
                    'compileOptions {\n        coreLibraryDesugaringEnabled true',
                    1,
                )
                dep_line = (
                    "    coreLibraryDesugaring 'com.android.tools:"
                    "desugar_jdk_libs:" + DESUGAR_VERSION + "'\n"
                )
            match = re.search(r'dependencies\s*\{', content)
            if match:
                insert_at = match.end()
                content = (
                    content[:insert_at] + '\n' + dep_line +
                    content[insert_at:]
                )
            else:
                content += '\ndependencies {\n' + dep_line + '}\n'
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print('gradle: desugaring enabled in', candidate)
            return
    print('gradle: WARNING no build.gradle found')


if __name__ == '__main__':
    patch_manifest()
    copy_audio()
    add_keep_xml()
    patch_gradle_desugaring()
    patch_root_subprojects_floor()
