import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/working_memory/models/task_entity.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TaskEntitySchema],
      directory: dir.path,
      inspector: true,
    );

    return _isar!;
  }

  static Future<void> dispose() async {
    await _isar?.close();
    _isar = null;
  }
}
