import 'package:military_exam/core/services/exam_run_context.dart';
import 'package:military_exam/features/exam_session/data/datasources/demo_exam_memory_store.dart';

DemoExamMemoryStore createDemoExamMemoryStore() => DemoExamMemoryStore();

ExamRunContext createExamRunContext([DemoExamMemoryStore? store]) =>
    ExamRunContext(store ?? DemoExamMemoryStore());

({ExamRunContext examRunContext, DemoExamMemoryStore demoMemoryStore})
    createLinkedDemoExamDependencies() {
  final demoMemoryStore = DemoExamMemoryStore();
  return (
    examRunContext: ExamRunContext(demoMemoryStore),
    demoMemoryStore: demoMemoryStore,
  );
}
