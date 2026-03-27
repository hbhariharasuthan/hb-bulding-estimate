import 'picked_upload.dart';
import 'web_image_picker_stub.dart'
    if (dart.library.html) 'web_image_picker_web.dart' as picker;

Future<PickedUpload?> pickImageForWeb() => picker.pickImageForWeb();
