// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_upload.dart';

Future<PickedUpload?> pickPlanFileForWeb() async {
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,.png,.jpg,.jpeg,.webp,.bmp,.tif,.tiff,.dwg,.dxf';
  input.click();
  await input.onChange.first;
  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) return null;

  final reader = html.FileReader();
  final completer = Completer<PickedUpload?>();
  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is! List<int>) {
      completer.complete(null);
      return;
    }
    completer.complete(
      PickedUpload(name: file.name, bytes: Uint8List.fromList(result)),
    );
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsArrayBuffer(file);
  return completer.future;
}

