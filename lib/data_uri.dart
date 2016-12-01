import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';

/// A utility to create data URLs
/// Data URLs are genreally of the format
/// data:[<MIME-type>][;charset=<encoding>][;base64],<data>
/// further reading: https://en.wikipedia.org/wiki/Data_URI_scheme
class DataUri {
  String mimeType;
  String encoding;
  String data;
  bool base64;

  DataUri(
      {String this.mimeType: 'application/octet-stream',
      String this.encoding,
      String this.data,
      bool this.base64: true});

  @override
  String toString() =>
      'data:${mimeType != null && mimeType.length > 0 ? mimeType : ""}${encoding != null && encoding.length > 0 ? ";charset=" + encoding : ""}${base64 ? ";base64" : ""},${data != null ? data : ""}';

  static base64EncodeString(String string) => window.btoa(string);
  static base64EncodeByteBuffer(ByteBuffer buf) =>
      BASE64.encode(buf.asUint8List().toList());
}
