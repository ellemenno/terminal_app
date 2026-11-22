import 'package:grinder/grinder.dart';
import 'tasks/tasks.dart' as task_utils;

void main(List<String> args) {
  task_utils.addAllTasks();
  grind(args);
}
