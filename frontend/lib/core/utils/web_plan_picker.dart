import 'picked_upload.dart';
import 'web_plan_picker_stub.dart'
    if (dart.library.html) 'web_plan_picker_web.dart' as picker;

Future<PickedUpload?> pickPlanFileForWeb() => picker.pickPlanFileForWeb();

