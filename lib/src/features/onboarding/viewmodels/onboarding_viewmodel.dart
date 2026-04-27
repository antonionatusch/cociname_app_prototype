import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consumer_onboarding_data.dart';
import '../models/cook_onboarding_data.dart';
import '../models/onboarding_question_definition.dart';
import '../models/onboarding_step.dart';
import '../models/profile_role.dart';
import '../repositories/onboarding_repository.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._onboardingRepository);

  final OnboardingRepository _onboardingRepository;

  final Set<ProfileRole> _selectedRoles = <ProfileRole>{};
  int _currentIndex = 0;
  bool _submitting = false;

  String consumerZoneLabel = '';
  final List<String> consumerPreferredFoodTypes = <String>[];
  String consumerAppUsageFrequency = '';
  final List<String> consumerOrderMotivations = <String>[];
  final List<String> consumerAllergenFilters = <String>[];
  final List<String> consumerDeliveryPreferences = <String>[];
  final List<String> consumerPaymentPreferences = <String>[];

  String cookBusinessName = '';
  final List<String> cookDishTypes = <String>[];
  String cookPrepLeadTime = '';
  String cookWeeklyOrderVolume = '';
  final List<String> cookDeliveryMethods = <String>[];
  final List<String> cookMainPainPoints = <String>[];
  String cookOperatingZone = '';

  static const List<OnboardingQuestionDefinition> _consumerQuestions = [
    OnboardingQuestionDefinition(
      id: 'consumer.zone_label',
      role: ProfileRole.consumer,
      title: '¿En que zona o barrio sueles pedir comida?',
      subtitle:
          'Usaremos esta referencia para personalizar la experiencia inicial.',
      inputType: OnboardingQuestionInputType.text,
      questionNumber: 1,
      totalQuestions: 7,
      placeholder: 'Ej. Equipetrol, Centro, Urbari',
    ),
    OnboardingQuestionDefinition(
      id: 'consumer.preferred_food_types',
      role: ProfileRole.consumer,
      title: '¿Que tipos de comida sueles pedir?',
      subtitle: 'Puedes seleccionar varias opciones.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 2,
      totalQuestions: 7,
      options: [
        'Comida casera',
        'Comida rapida',
        'Postres y snacks',
        'Comida saludable',
        'Bebidas frias',
        'Platos tipicos',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'consumer.app_usage_frequency',
      role: ProfileRole.consumer,
      title: '¿Con que frecuencia usas apps de comida?',
      subtitle:
          'Esto ayudara a priorizar recomendaciones y recordatorios futuros.',
      inputType: OnboardingQuestionInputType.singleChoice,
      questionNumber: 3,
      totalQuestions: 7,
      options: [
        'Todos los dias o casi diario',
        '3 a 4 veces por semana',
        '1 a 2 veces por semana',
        '1 vez por semana',
        'Menos de una vez por semana',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'consumer.order_motivations',
      role: ProfileRole.consumer,
      title: '¿Por que motivos pides comida en linea?',
      subtitle: 'Selecciona lo que mas se acerque a tu rutina.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 4,
      totalQuestions: 7,
      options: [
        'Comodidad',
        'Falta de tiempo para cocinar',
        'Curiosidad por nuevos emprendimientos',
        'Prefiero evitar filas o traslados',
        'Promociones o descuentos',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'consumer.allergen_filters',
      role: ProfileRole.consumer,
      title: '¿Que alergenos o restricciones quieres filtrar?',
      subtitle:
          'Esta informacion se usara como preferencia preventiva, no como criterio medico.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 5,
      totalQuestions: 7,
      options: [
        'Gluten',
        'Lactosa',
        'Mani',
        'Mariscos',
        'Huevos',
        'Sin restricciones por ahora',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'consumer.delivery_preferences',
      role: ProfileRole.consumer,
      title: '¿Como prefieres recibir tu pedido?',
      subtitle: 'Esto nos ayudara a priorizar tipos de oferta.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 6,
      totalQuestions: 7,
      options: [
        'Cliente recoge el pedido',
        'Entrega personal del cocinero',
        'Delivery tercerizado',
        'Me adapto segun el caso',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'consumer.payment_preferences',
      role: ProfileRole.consumer,
      title: '¿Que medios de pago prefieres usar?',
      subtitle:
          'Aunque el MVP no procesa pagos dentro de la app, esto alimenta tu perfil inicial.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 7,
      totalQuestions: 7,
      options: ['QR', 'Efectivo', 'Tarjeta', 'Transferencia bancaria'],
    ),
  ];

  static const List<OnboardingQuestionDefinition> _cookQuestions = [
    OnboardingQuestionDefinition(
      id: 'cook.business_name',
      role: ProfileRole.cook,
      title: '¿Como se llama tu emprendimiento o perfil visible?',
      subtitle:
          'Puede ser tu marca, tu nombre o una referencia comercial breve.',
      inputType: OnboardingQuestionInputType.text,
      questionNumber: 1,
      totalQuestions: 7,
      placeholder: 'Ej. Empanadas Dona Rosa',
    ),
    OnboardingQuestionDefinition(
      id: 'cook.dish_types',
      role: ProfileRole.cook,
      title: '¿Que tipos de platos cocinas para vender?',
      subtitle: 'Selecciona las categorias que mejor describen tu oferta.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 2,
      totalQuestions: 7,
      options: [
        'Comida casera',
        'Comida rapida',
        'Postres y snacks',
        'Platos tipicos',
        'Bebidas frias',
        'Comida saludable',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'cook.prep_lead_time',
      role: ProfileRole.cook,
      title: '¿Con cuanta anticipacion preparas tus pedidos?',
      subtitle: 'Esto se mostrara como contexto operativo del emprendimiento.',
      inputType: OnboardingQuestionInputType.singleChoice,
      questionNumber: 3,
      totalQuestions: 7,
      options: [
        'El mismo dia, unas horas antes',
        'Cuando entra el pedido',
        'Un dia antes',
        'Depende del plato',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'cook.weekly_order_volume',
      role: ProfileRole.cook,
      title: '¿Cuantos pedidos elaboras por semana?',
      subtitle: 'Escoge el rango mas cercano a tu operacion actual.',
      inputType: OnboardingQuestionInputType.singleChoice,
      questionNumber: 4,
      totalQuestions: 7,
      options: [
        '1 a 5 pedidos por semana',
        '6 a 10 pedidos por semana',
        '11 a 20 pedidos por semana',
        'Mas de 20 pedidos por semana',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'cook.delivery_methods',
      role: ProfileRole.cook,
      title: '¿Como gestionas la entrega de tus pedidos?',
      subtitle: 'Selecciona todas las modalidades que ya utilizas.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 5,
      totalQuestions: 7,
      options: [
        'Cliente recoge el pedido',
        'Entrega personalmente',
        'Uso un servicio de delivery tercerizado',
        'Lo coordino caso por caso',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'cook.main_pain_points',
      role: ProfileRole.cook,
      title: '¿Que te cuesta mas al vender comida?',
      subtitle:
          'Esto nos ayudara a enriquecer funciones futuras del lado del cocinero.',
      inputType: OnboardingQuestionInputType.multiChoice,
      questionNumber: 6,
      totalQuestions: 7,
      options: [
        'Conseguir mas clientes',
        'Coordinar pedidos y entregas',
        'Organizar el tiempo de cocina',
        'Definir precios',
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'cook.operating_zone',
      role: ProfileRole.cook,
      title: '¿Desde que zona operas normalmente?',
      subtitle: 'Esta referencia nos ayudara a ubicar tu oferta en la app.',
      inputType: OnboardingQuestionInputType.text,
      questionNumber: 7,
      totalQuestions: 7,
      placeholder: 'Ej. Equipetrol, Centro, Santos Dumont',
    ),
  ];

  Set<ProfileRole> get selectedRoles => Set.unmodifiable(_selectedRoles);
  bool get submitting => _submitting;
  int get currentIndex => _currentIndex;
  List<OnboardingStep> get steps {
    final items = <OnboardingStep>[const OnboardingStep.roleSelection()];

    if (_selectedRoles.contains(ProfileRole.consumer)) {
      items.addAll(_consumerQuestions.map(OnboardingStep.question));
    }

    if (_selectedRoles.contains(ProfileRole.cook)) {
      items.addAll(_cookQuestions.map(OnboardingStep.question));
      items.add(const OnboardingStep.subscription());
    }

    return items;
  }

  OnboardingStep get currentStep => steps[_currentIndex];
  bool get canGoBack => _currentIndex > 0;
  bool get isLastStep => _currentIndex == steps.length - 1;
  double get overallProgress => (_currentIndex + 1) / steps.length;

  String get continueLabel {
    if (currentStep.kind == OnboardingStepKind.subscription) {
      return 'Finalizar onboarding';
    }
    if (isLastStep) {
      return 'Guardar perfiles';
    }
    return 'Continuar';
  }

  void toggleRole(ProfileRole role) {
    if (role == ProfileRole.admin) return;

    if (_selectedRoles.contains(role)) {
      _selectedRoles.remove(role);
    } else {
      _selectedRoles.add(role);
    }

    if (_currentIndex >= steps.length) {
      _currentIndex = steps.length - 1;
    }
    notifyListeners();
  }

  void previousStep() {
    if (!canGoBack) return;
    _currentIndex -= 1;
    notifyListeners();
  }

  Future<String?> continueFlow() async {
    if (!canContinue) {
      return 'Completa esta parte del perfil antes de continuar.';
    }

    if (!isLastStep) {
      _currentIndex += 1;
      notifyListeners();
      return null;
    }

    return submit();
  }

  bool get canContinue {
    switch (currentStep.kind) {
      case OnboardingStepKind.roleSelection:
        return _selectedRoles.isNotEmpty;
      case OnboardingStepKind.subscription:
        return true;
      case OnboardingStepKind.question:
        return _isQuestionAnswered(currentStep.question!);
    }
  }

  String textValueFor(OnboardingQuestionDefinition question) {
    switch (question.id) {
      case 'consumer.zone_label':
        return consumerZoneLabel;
      case 'cook.business_name':
        return cookBusinessName;
      case 'cook.operating_zone':
        return cookOperatingZone;
      default:
        return '';
    }
  }

  String singleChoiceValueFor(OnboardingQuestionDefinition question) {
    switch (question.id) {
      case 'consumer.app_usage_frequency':
        return consumerAppUsageFrequency;
      case 'cook.prep_lead_time':
        return cookPrepLeadTime;
      case 'cook.weekly_order_volume':
        return cookWeeklyOrderVolume;
      default:
        return '';
    }
  }

  List<String> selectedOptionsFor(OnboardingQuestionDefinition question) {
    switch (question.id) {
      case 'consumer.preferred_food_types':
        return consumerPreferredFoodTypes;
      case 'consumer.order_motivations':
        return consumerOrderMotivations;
      case 'consumer.allergen_filters':
        return consumerAllergenFilters;
      case 'consumer.delivery_preferences':
        return consumerDeliveryPreferences;
      case 'consumer.payment_preferences':
        return consumerPaymentPreferences;
      case 'cook.dish_types':
        return cookDishTypes;
      case 'cook.delivery_methods':
        return cookDeliveryMethods;
      case 'cook.main_pain_points':
        return cookMainPainPoints;
      default:
        return const <String>[];
    }
  }

  void updateTextAnswer(OnboardingQuestionDefinition question, String value) {
    switch (question.id) {
      case 'consumer.zone_label':
        consumerZoneLabel = value;
        break;
      case 'cook.business_name':
        cookBusinessName = value;
        break;
      case 'cook.operating_zone':
        cookOperatingZone = value;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void selectSingleChoice(OnboardingQuestionDefinition question, String value) {
    switch (question.id) {
      case 'consumer.app_usage_frequency':
        consumerAppUsageFrequency = value;
        break;
      case 'cook.prep_lead_time':
        cookPrepLeadTime = value;
        break;
      case 'cook.weekly_order_volume':
        cookWeeklyOrderVolume = value;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void toggleMultiChoice(OnboardingQuestionDefinition question, String value) {
    final list = selectedOptionsFor(question);
    if (list.contains(value)) {
      list.remove(value);
    } else {
      if (question.id == 'consumer.allergen_filters' &&
          value == 'Sin restricciones por ahora') {
        list
          ..clear()
          ..add(value);
      } else {
        list.remove('Sin restricciones por ahora');
        list.add(value);
      }
    }
    notifyListeners();
  }

  Future<String?> submit() async {
    _submitting = true;
    notifyListeners();

    try {
      await _onboardingRepository.completeOnboarding(
        roles: _selectedRoles,
        consumerData:
            _selectedRoles.contains(ProfileRole.consumer)
                ? ConsumerOnboardingData(
                  zoneLabel: consumerZoneLabel.trim(),
                  preferredFoodTypes: List<String>.from(
                    consumerPreferredFoodTypes,
                  ),
                  appUsageFrequency: consumerAppUsageFrequency,
                  orderMotivations: List<String>.from(consumerOrderMotivations),
                  allergenFilters: List<String>.from(consumerAllergenFilters),
                  deliveryPreferences: List<String>.from(
                    consumerDeliveryPreferences,
                  ),
                  paymentPreferences: List<String>.from(
                    consumerPaymentPreferences,
                  ),
                )
                : null,
        cookData:
            _selectedRoles.contains(ProfileRole.cook)
                ? CookOnboardingData(
                  businessName: cookBusinessName.trim(),
                  dishTypes: List<String>.from(cookDishTypes),
                  prepLeadTime: cookPrepLeadTime,
                  weeklyOrderVolume: cookWeeklyOrderVolume,
                  deliveryMethods: List<String>.from(cookDeliveryMethods),
                  mainPainPoints: List<String>.from(cookMainPainPoints),
                  operatingZone: cookOperatingZone.trim(),
                )
                : null,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } on PostgrestException catch (error) {
      return error.message;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  bool _isQuestionAnswered(OnboardingQuestionDefinition question) {
    switch (question.inputType) {
      case OnboardingQuestionInputType.text:
        return textValueFor(question).trim().isNotEmpty;
      case OnboardingQuestionInputType.singleChoice:
        return singleChoiceValueFor(question).trim().isNotEmpty;
      case OnboardingQuestionInputType.multiChoice:
        return selectedOptionsFor(question).isNotEmpty;
    }
  }
}
