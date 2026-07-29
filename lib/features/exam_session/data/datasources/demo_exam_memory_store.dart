import '../../../../shared/domain/entities/exam_entities.dart';
import '../models/exam_answer_draft_model.dart';
import '../models/exam_session_model.dart';

/// In-memory answer/session store for onboarding demo exams only.
class DemoExamMemoryStore {
  final Map<String, ExamAnswerDraftModel> _drafts = {};
  final List<WrittenAnswerImage> _images = [];
  ExamSessionModel? _session;

  Map<String, ExamAnswerDraftModel> get drafts =>
      Map<String, ExamAnswerDraftModel>.unmodifiable(_drafts);

  List<WrittenAnswerImage> get images =>
      List<WrittenAnswerImage>.unmodifiable(_images);

  ExamSessionModel? get session => _session;

  void setSession(ExamSessionModel session) {
    _session = session;
  }

  void upsertDraft(ExamAnswerDraftModel draft) {
    _drafts[draft.questionId] = draft;
  }

  void addImage(WrittenAnswerImage image) {
    _images.removeWhere((entry) => entry.localId == image.localId);
    _images.add(image);
  }

  void replaceImages(List<WrittenAnswerImage> images) {
    _images
      ..clear()
      ..addAll(images);
  }

  void removeImage(String localId) {
    _images.removeWhere((entry) => entry.localId == localId);
  }

  void clear() {
    _drafts.clear();
    _images.clear();
    _session = null;
  }
}
