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
@TestOn('browser')

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:font_face_observer/data_uri.dart';

void main() {
  group('DataUri', () {
    test('should build data uri correctly', () {
      DataUri di = new DataUri();
      expect(di.toString(), equals('data:application/octet-stream;base64,'));
      
      di.data = DataUri.base64EncodeString('test');
      di.mimeType = 'text/plain';
      di.encoding = 'utf-8';
      expect(di.toString(), equals('data:text/plain;charset=utf-8;base64,dGVzdA=='));

      di.data = DataUri.base64EncodeByteBuffer(new Uint8List(8).buffer);
      expect(di.toString(), equals('data:text/plain;charset=utf-8;base64,AAAAAAAAAAA='));

      di.data = null;
      di.encoding = null;
      di.isDataBase64Encoded = false;
      di.mimeType = null;
      expect(di.toString(), equals('data:,'));

      di.data = '';
      di.encoding = '';
      di.mimeType = '';
      expect(di.toString(), equals('data:,'));
    });
  });
}
