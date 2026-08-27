#!/usr/bin/env python3
"""إضافة keep.xml لمنع حذف أصوات الأذان في release / keep.xml to preserve raw sounds.

Resource shrinking في release ي删 أي مورد غير مُشار إليه من XML/كود مباشر.
أصوات الأذان تُطلب بأسماء نصية من Dart فتُحذف — keep.xml يمنع ذلك.
Resource shrinking removes raw sounds referenced only by name from Dart;
keep.xml forces them to be retained.
"""
import os

SCAFFOLD = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'scaffold')

KEEP_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@raw/adhan_regular,@raw/adhan_fajr"/>
"""


def add_keep_xml() -> None:
    xml_dir = os.path.join(SCAFFOLD, 'android/app/src/main/res/xml')
    os.makedirs(xml_dir, exist_ok=True)
    path = os.path.join(xml_dir, 'keep.xml')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(KEEP_XML)
    print('keep.xml written to res/xml')


if __name__ == '__main__':
    add_keep_xml()
