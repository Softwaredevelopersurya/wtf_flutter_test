class AppStrings {
  // Section 11: Exact UI Copy
  static const String emptyChat = "No messages yet. Start the conversation.";
  static const String requestSent = "Call requested. Waiting for trainer approval.";
  static String callApproved(String date, String time) => "Call approved for $date $time.";
  static String callApprovedShort(String time) => "Call approved for $time.";
  static String callDeclined(String reason) => "Call request declined. Reason: $reason.";
  static const String joinPrompt = "Ready to join? Check mic and camera.";
  static const String sessionEnded = "Session saved to your logs.";

  // Quick replies
  static const List<String> quickReplies = [
    "Got it 👍",
    "Can we talk at 6?",
    "Share plan?",
  ];

  // Seed Personas
  static const String memberSeedName = "DK";
  static const String memberSeedId = "user_member_dk";
  static const String trainerSeedName = "Aarav (Lead Trainer)";
  static const String trainerSeedId = "user_trainer_aarav";
}
