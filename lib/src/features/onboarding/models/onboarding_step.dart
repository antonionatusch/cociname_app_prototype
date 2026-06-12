import 'onboarding_question_definition.dart';

enum OnboardingStepKind { roleSelection, question, subscription }

class OnboardingStep {
  const OnboardingStep.roleSelection()
    : kind = OnboardingStepKind.roleSelection,
      question = null;

  const OnboardingStep.question(this.question)
    : kind = OnboardingStepKind.question;

  const OnboardingStep.subscription()
    : kind = OnboardingStepKind.subscription,
      question = null;

  final OnboardingStepKind kind;
  final OnboardingQuestionDefinition? question;
}
