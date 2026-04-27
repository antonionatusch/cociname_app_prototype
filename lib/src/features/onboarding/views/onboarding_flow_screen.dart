import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/onboarding_question_definition.dart';
import '../models/onboarding_step.dart';
import '../models/profile_role.dart';
import '../repositories/onboarding_repository.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({
    super.key,
    required this.onboardingRepository,
    required this.onCompleted,
  });

  final OnboardingRepository onboardingRepository;
  final Future<void> Function() onCompleted;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(widget.onboardingRepository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final wasLastStep = _viewModel.isLastStep;
    final error = await _viewModel.continueFlow();
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (wasLastStep) {
      await widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final currentStep = _viewModel.currentStep;

        return Scaffold(
          appBar: AppBar(title: const Text('Perfil gastronomico')),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: _viewModel.overallProgress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(12),
                        backgroundColor: AppTheme.surfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _headerForStep(currentStep),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildStep(currentStep),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      if (_viewModel.canGoBack)
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _viewModel.submitting
                                    ? null
                                    : _viewModel.previousStep,
                            child: const Text('Atras'),
                          ),
                        ),
                      if (_viewModel.canGoBack) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _viewModel.submitting ? null : _continue,
                          child: Text(
                            _viewModel.submitting
                                ? 'Guardando...'
                                : _viewModel.continueLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(OnboardingStep step) {
    switch (step.kind) {
      case OnboardingStepKind.roleSelection:
        return _buildRoleSelection();
      case OnboardingStepKind.subscription:
        return _buildSubscriptionPlaceholder();
      case OnboardingStepKind.question:
        return _buildQuestion(step.question!);
    }
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Que perfil quieres activar primero?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Puedes escoger consumidor, cocinero o ambos. Si eliges ambos, primero responderas las 7 preguntas de consumidor y luego las 7 de cocinero.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildRoleCard(ProfileRole.consumer),
            _buildRoleCard(ProfileRole.cook),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(ProfileRole role) {
    final selected = _viewModel.selectedRoles.contains(role);
    return SizedBox(
      width: 260,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _viewModel.toggleRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppTheme.brandSoft : AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppTheme.brandPrimary : AppTheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconForRole(role), color: AppTheme.brandPrimaryDark),
              const SizedBox(height: 12),
              Text(role.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(role.shortDescription),
              const SizedBox(height: 12),
              Text(
                selected ? 'Seleccionado' : 'Tocar para elegir',
                style: TextStyle(
                  color:
                      selected
                          ? AppTheme.brandPrimaryDark
                          : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(OnboardingQuestionDefinition question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(question.subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        switch (question.inputType) {
          OnboardingQuestionInputType.text => TextFormField(
            key: ValueKey(question.id),
            initialValue: _viewModel.textValueFor(question),
            onChanged: (value) => _viewModel.updateTextAnswer(question, value),
            decoration: InputDecoration(
              labelText: 'Tu respuesta',
              hintText: question.placeholder,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          OnboardingQuestionInputType.singleChoice => Column(
            children:
                question.options
                    .map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap:
                              () => _viewModel.selectSingleChoice(
                                question,
                                option,
                              ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  _viewModel.singleChoiceValueFor(question) ==
                                          option
                                      ? AppTheme.brandSoft
                                      : AppTheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    _viewModel.singleChoiceValueFor(question) ==
                                            option
                                        ? AppTheme.brandPrimary
                                        : AppTheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: option,
                                  groupValue: _viewModel.singleChoiceValueFor(
                                    question,
                                  ),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    _viewModel.selectSingleChoice(
                                      question,
                                      value,
                                    );
                                  },
                                ),
                                Expanded(child: Text(option)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          OnboardingQuestionInputType.multiChoice => Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                question.options
                    .map(
                      (option) => FilterChip(
                        label: Text(option),
                        selected: _viewModel
                            .selectedOptionsFor(question)
                            .contains(option),
                        onSelected:
                            (_) =>
                                _viewModel.toggleMultiChoice(question, option),
                      ),
                    )
                    .toList(),
          ),
        },
      ],
    );
  }

  Widget _buildSubscriptionPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suscripcion para cocineros',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'La logica de eleccion de suscripciones todavia esta en construccion. Por ahora, cualquier perfil de cocinero iniciara con el plan Base.',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.brandSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan asignado: Base',
                style: TextStyle(
                  color: AppTheme.brandPrimaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Seguiras al siguiente paso con una configuracion inicial pensada para pruebas del MVP.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _headerForStep(OnboardingStep step) {
    switch (step.kind) {
      case OnboardingStepKind.roleSelection:
        return 'Paso 1 de ${_viewModel.steps.length}';
      case OnboardingStepKind.subscription:
        return 'Cocinero · Suscripcion';
      case OnboardingStepKind.question:
        final question = step.question!;
        return '${question.role.label} · ${question.questionNumber}/${question.totalQuestions}';
    }
  }

  IconData _iconForRole(ProfileRole role) {
    switch (role) {
      case ProfileRole.consumer:
        return Icons.shopping_bag_outlined;
      case ProfileRole.cook:
        return Icons.storefront_outlined;
      case ProfileRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
