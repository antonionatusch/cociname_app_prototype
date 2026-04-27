import 'profile_role.dart';

enum OnboardingQuestionInputType { text, singleChoice, multiChoice }

class OnboardingQuestionDefinition {
  const OnboardingQuestionDefinition({
    required this.id,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.inputType,
    required this.questionNumber,
    required this.totalQuestions,
    this.options = const <String>[],
    this.placeholder,
  });

  final String id;
  final ProfileRole role;
  final String title;
  final String subtitle;
  final OnboardingQuestionInputType inputType;
  final int questionNumber;
  final int totalQuestions;
  final List<String> options;
  final String? placeholder;
}
