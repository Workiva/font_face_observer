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
  bool isDataBase64Encoded;

  DataUri(
      {String this.mimeType: 'application/octet-stream',
      String this.encoding,
      String this.data,
      bool this.isDataBase64Encoded: true});

  @override
  String toString() =>
      'data:${mimeType != null && mimeType.length > 0 ? mimeType : ""}${encoding != null && encoding.length > 0 ? ";charset=" + encoding : ""}${isDataBase64Encoded ? ";base64" : ""},${data != null ? data : ""}';

  // Static method to encode a string to base64
  static String base64EncodeString(String string) => window.btoa(string);

  // Static method to encode a ByteBuffer (which you get back from an
  // HttpRequest) to base64 String
  static String base64EncodeByteBuffer(ByteBuffer buf) =>
      BASE64.encode(buf.asUint8List().toList());
}
