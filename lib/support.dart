/*
Copyright 2017 Workiva Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

This software or document includes material copied from or derived 
from fontfaceobserver (https://github.com/bramstein/fontfaceobserver), 
Copyright (c) 2014 - Bram Stein, which is licensed under the following terms:

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions 
are met:
 
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer. 
 2. Redistributions in binary form must reproduce the above copyright 
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software or document includes material copied from or derived from 
CSS Font Loading Module Level 3 (https://drafts.csswg.org/css-font-loading/)
Copyright © 2017 W3C® (MIT, ERCIM, Keio, Beihang) which is licensed 
under the following terms:

By obtaining and/or copying this work, you (the licensee) agree that you 
have read, understood, and will comply with the following terms and conditions.
Permission to copy, modify, and distribute this work, with or without 
modification, for any purpose and without fee or royalty is hereby granted, 
provided that you include the following on ALL copies of the work or portions 
thereof, including modifications:
The full text of this NOTICE in a location viewable to users of the 
redistributed or derivative work. Any pre-existing intellectual property 
disclaimers, notices, or terms and conditions. If none exist, the W3C 
Software and Document Short Notice should be included.
Notice of any changes or modifications, through a copyright statement 
on the new code or document such as "This software or document 
includes material copied from or derived from 
[title and URI of the W3C document]. 
Copyright © [YEAR] W3C® (MIT, ERCIM, Keio, Beihang)."

https://www.w3.org/Consortium/Legal/2015/copyright-software-and-document
*/
import 'dart:html';

/// Is true if this browser is WebKit and it has the fallback bug
/// which is present in WebKit 536.11 and earlier.
final bool hasWebkitFallbackBug =
    _hasWebKitFallbackBug(window.navigator.userAgent);

/// Is true if the current browser supports the CSS font face stretch property
final bool supportsStretch = _supportsStretch();

/// Is true if the current browser supports the Font Face API
final bool supportsNativeFontLoading = _supportsNativeFontLoading();

/// Returns true if the browser supports font-style in the font short-hand syntax.
bool _supportsStretch() {
  final Element div = document.createElement('div');
  try {
    // Detect if the browser supports the CSS font-stretch property by trying
    // to set it on a new empty div. Using condensed will cause an exception
    // in browsers that don't support it.
    div.style.font = 'condensed 100px sans-serif';
  } on Exception {
    // ignore exceptions intentionally
  }
  // If the font style still has a value, that means the browser accepts
  // stretch as a valid value and supports it
  return div.style.font != '';
}

/// Returns true if the browser supports the FontFace API to load fonts
bool _supportsNativeFontLoading() {
  bool supports = true;
  try {
    // Detect if the browser supports the FontFace API by trying
    // to access document.fonts.status below. If there is no exception,
    // it is supported. If there is an exception, then it is not supported.

    // ignore: unnecessary_statements
    document.fonts.status;
  } on Exception {
    supports = false;
  }
  return supports;
}

/// Returns true if this browser is WebKit and it has the fallback bug
/// which is present in WebKit 536.11 and earlier.
bool _hasWebKitFallbackBug(String userAgent) {
  final RegExp regex = RegExp('AppleWebKit\/([0-9]+)(?:\.([0-9]+))');
  final Iterable<Match> matches = regex.allMatches(userAgent);
  if (matches == null || matches.isEmpty) {
    return false;
  }
  final Match match = matches.first;
  if (match == null) {
    return false;
  }
  final num major = int.parse(match.group(1));
  final num minor = int.parse(match.group(2));
  return major < 536 || (major == 536 && minor <= 11);
}
