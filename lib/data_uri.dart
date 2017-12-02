/*
Copyright 2016 Workiva Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';

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
/// DataUri di = new DataUri();
///   ..data = DataUri.base64EncodeString('test');
///   ..mimeType = 'text/plain';
///   ..encoding = 'utf-8';
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
      {this.mimeType: 'application/octet-stream',
      this.encoding,
      this.data,
      this.isDataBase64Encoded: true});

  @override
  String toString() =>
      'data:${mimeType != null && mimeType.length > 0 ? mimeType : ""}${encoding != null && encoding.length > 0 ? ";charset=" + encoding : ""}${isDataBase64Encoded ? ";base64" : ""},${data != null ? data : ""}';

  /// Static method to encode a string to base64
  static String base64EncodeString(String string) => window.btoa(string);

  /// Static method to encode a ByteBuffer (which you get back from an
  /// HttpRequest) to base64 String
  static String base64EncodeByteBuffer(ByteBuffer buf) =>
      BASE64.encode(buf.asUint8List().toList());
}
