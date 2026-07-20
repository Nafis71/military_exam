import 'package:equatable/equatable.dart';

enum ExamSubmitReviewViewState {
  loading,
  summary,
  waitingForNetwork,
}

class ExamSubmitReviewState extends Equatable {
  const ExamSubmitReviewState({
    required this.viewState,
    this.syncWarning,
    this.errorMessage,
    this.waitingErrorMessage,
    this.stopAutoRetry = false,
  });

  final ExamSubmitReviewViewState viewState;
  final String? syncWarning;
  final String? errorMessage;
  final String? waitingErrorMessage;
  final bool stopAutoRetry;

  ExamSubmitReviewState copyWith({
    ExamSubmitReviewViewState? viewState,
    String? syncWarning,
    String? errorMessage,
    String? waitingErrorMessage,
    bool? stopAutoRetry,
    bool clearSyncWarning = false,
    bool clearErrorMessage = false,
    bool clearWaitingErrorMessage = false,
  }) {
    return ExamSubmitReviewState(
      viewState: viewState ?? this.viewState,
      syncWarning: clearSyncWarning ? null : syncWarning ?? this.syncWarning,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      waitingErrorMessage: clearWaitingErrorMessage
          ? null
          : waitingErrorMessage ?? this.waitingErrorMessage,
      stopAutoRetry: stopAutoRetry ?? this.stopAutoRetry,
    );
  }

  @override
  List<Object?> get props => [
        viewState,
        syncWarning,
        errorMessage,
        waitingErrorMessage,
        stopAutoRetry,
      ];
}
