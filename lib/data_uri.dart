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

import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

/// A utility to create data URIs
///
/// Data URIs are generally of the format
///
/// ```
///   data:[mimeType][;charset=encoding][;base64],data
/// ```
///
/// [Further Reading on Data URI Scheme](https://en.wikipedia.org/wiki/Data_URI_scheme)
///
/// Example Usage:
/// ```
/// DataUri di = new DataUri(
///   data: DataUri.base64EncodeString('test');
///   mimeType: 'text/plain';
///   encoding: 'utf-8');
/// di.toString(); # data:text/plain;charset=utf-8;base64,dGVzdA==
/// ```

class DataUri {
  /// The mimetype of the data. If null or empty it will be omitted
  String mimeType;

  /// The content encoding of the data.  If null or empty it will be omitted
  String encoding;

  /// The data as a String
  String data;

  /// Whether or not the data is base64 encoded
  bool isDataBase64Encoded;

  /// Construct a new DataUri. Assume that [data] is base64 encoded unless
  /// [isDataBase64Encoded] is passed in as false
  DataUri(
      {this.mimeType = 'application/octet-stream',
      this.encoding = '',
      this.data = '',
      this.isDataBase64Encoded = true});

  @override
  String toString() =>
      'data:${mimeType.isNotEmpty ? mimeType : ""}${encoding.isNotEmpty ? ";charset=$encoding" : ""}${isDataBase64Encoded ? ";base64" : ""},${data}';

  /// Static method to encode a string to base64
  static String base64EncodeString(String string) => window.btoa(string);

  /// Static method to encode a ByteBuffer (which you get back from an
  /// HttpRequest) to base64 String
  static String base64EncodeByteBuffer(ByteBuffer buf) =>
      base64.encode(buf.asUint8List().toList());
}
