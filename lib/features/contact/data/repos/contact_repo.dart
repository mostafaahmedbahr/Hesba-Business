/// Data source for submitting customer feedback (complaints / suggestions).
abstract class ContactRepo {
  /// Submits a feedback message with a title and description.
  /// Returns the Firestore document id on success.
  Future<String> submitFeedback({
    required String type,
    required String title,
    required String description,
  });
}