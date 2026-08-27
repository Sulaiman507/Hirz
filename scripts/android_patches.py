#!/usr/bin/env python3
"""تعديلات أندرويد بعد flutter create في CI / Native Android patches after scaffold.

١) حقن الصلاحيات في AndroidManifest.xml (إشعارات + منبه دقيق + اهتزاز + اقلاع)
٢) نسخ ملفات الأذان إلى android/app/src/main/res/raw لقنوات الإشعار
٣) تمكين core library desugaring (مطلوب لمكتبة الإشعارات مع minSdk < 26)
٤) كتابة BootReceiver.class + تسجيله في الـ manifest لإعادة جدولة الأذان بعد reboot
"""
import os
import re
import shutil

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
    for name in ('adhan_regular.mp3', 'adhan_fajr.mp3'):
        shutil.copy(os.path.join(src_dir, name), os.path.join(raw_dir, name))
        print('audio:', name, '-> res/raw')


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


# keep.xml: منع shrinkResources من حذف أصوات الأذان في release
# keep.xml: prevent shrinkResources from stripping adhan sounds in release
import subprocess
subprocess.run(['python3', os.path.join(ROOT, 'scripts', 'add_keep_xml.py')], check=False)


# BootReceiver: إعادة جدولة الأذان عند إقلاع الجهاز
# BootReceiver: reschedule adhan after device boot
def _boot_receiver_package() -> str:
    # نحاول قراءة package من AndroidManifest.xml
    try:
        path = os.path.join(SCAFFOLD, 'android/app/src/main/AndroidManifest.xml')
        with open(path, encoding='utf-8') as f:
            content = f.read()
        m = re.search(r'package="([^"]+)"', content)
        if m is not None and m.group(1) is not None and m.group(1).strip() != '':
            return m.group(1).strip()
    except Exception:
        pass
    return 'dev.hirz'


def _write_boot_receiver() -> None:
    pkg = _boot_receiver_package()
    pkg_dir = pkg.replace('.', os.sep)
    java_dir = os.path.join(SCAFFOLD, 'android/app/src/main/java', pkg_dir)
    os.makedirs(java_dir, exist_ok=True)
    receiver_path = os.path.join(java_dir, 'BootReceiver.java')
    with open(receiver_path, 'w', encoding='utf-8') as f:
        f.write('''package ''' + pkg + ''';

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

// يعيد تشغيل التطبيق بعد الإقلاع لتفعيل reschedule callback
// Restarts the app after boot to trigger reschedule callback
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent != null && Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Log.i("Hirz", "BootReceiver: rescheduling adhans");
            Intent i = new Intent(context, MainActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(i);
        }
    }
}
''')
    print('BootReceiver written to', receiver_path)


def patch_boot_receiver_manifest() -> None:
    path = os.path.join(SCAFFOLD, 'android/app/src/main/AndroidManifest.xml')
    with open(path, encoding='utf-8') as f:
        content = f.read()
    pkg = _boot_receiver_package()
    receiver_block = (
        '        <receiver\n'
        '            android:name=".BootReceiver"\n'
        '            android:enabled="true"\n'
        '            android:exported="true">\n'
        '            <intent-filter>\n'
        '                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n'
        '                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>\n'
        '            </intent-filter>\n'
        '        </receiver>\n'
    )
    if 'BootReceiver' in content:
        print('manifest: BootReceiver already present')
        return
    content = content.replace('</application>', receiver_block + '    </application>', 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('manifest: injected BootReceiver')


if __name__ == '__main__':
    patch_manifest()
    copy_audio()
    patch_gradle_desugaring()
    patch_root_subprojects_floor()
    _write_boot_receiver()
    patch_boot_receiver_manifest()
