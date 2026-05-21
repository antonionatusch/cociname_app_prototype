import 'package:cociname_app/src/features/consumer/models/consumer_request.dart';
import 'package:cociname_app/src/features/dish_publication/models/dish_publication.dart';
import 'package:cociname_app/src/features/offers/models/cook_offer.dart';
import 'package:cociname_app/src/features/offers/views/consumer_offers_screen.dart';
import 'package:cociname_app/src/features/offers/views/create_offer_sheet.dart';
import 'package:cociname_app/src/features/offers/views/offer_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offer detail handles long text without flex overflow', (
    tester,
  ) async {
    await _setSmallSurface(tester);

    await tester.pumpWidget(
      MaterialApp(home: OfferDetailScreen(offer: _longTextOffer())),
    );
    await tester.pump();

    _expectNoLayoutException(tester);
  });

  testWidgets('consumer offers cards handle long text without flex overflow', (
    tester,
  ) async {
    await _setSmallSurface(tester);
    final offer = _longTextOffer();

    await tester.pumpWidget(
      MaterialApp(
        home: ConsumerOffersScreen(
          offers: [offer],
          publications: {offer.publicationId: _longTextPublication()},
        ),
      ),
    );
    await tester.pump();

    _expectNoLayoutException(tester);
  });

  testWidgets('create offer sheet scrolls long request data without overflow', (
    tester,
  ) async {
    await _setSmallSurface(tester, size: const Size(320, 420));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateOfferSheet(
            request: _longTextRequest(),
            publications: [_longTextPublication()],
          ),
        ),
      ),
    );
    await tester.pump();

    _expectNoLayoutException(tester);
  });
}

Future<void> _setSmallSurface(
  WidgetTester tester, {
  Size size = const Size(360, 640),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void _expectNoLayoutException(WidgetTester tester) {
  final exception = tester.takeException();
  expect(exception, isNull);
}

CookOffer _longTextOffer() {
  return CookOffer(
    id: 'offer-1',
    requestId: 'request-1',
    publicationId: 'publication-1',
    cookProfileId: 'cook-1',
    price: 123.45,
    requestedQuantity: 12,
    estimatedMinutes: 45,
    message:
        'Mensaje largo del cocinero con detalles sobre disponibilidad, empaques, horarios y preparación especial para validar que la tarjeta no se rompa.',
    createdAt: DateTime(2026, 5, 21),
    dishTitle:
        'Empanadas integrales rellenas de queso artesanal con nombre extremadamente largo',
    dishDescription:
        'Descripción muy larga del plato para validar que el detalle permita scroll y no produzca errores visuales de overflow cuando la pantalla es pequeña.',
    cookBusinessName:
        'Cocina familiar artesanal con nombre comercial muy largo de Santa Cruz',
    cookRatingAverage: 4.8,
    dishRatingAverage: 4.9,
    dishRatingCount: 27,
    distanceKm: 2.4,
    publicationZoneLabel:
        'Avenida con nombre largo, edificio con referencia larga, zona norte',
    ingredients: const [
      OfferIngredientItem(
        name: 'Harina integral de trigo con descripción larga',
        source: 'cook_confirmed',
        isConfirmedByCook: true,
      ),
      OfferIngredientItem(
        name: 'Queso artesanal madurado con etiqueta extensa',
        source: 'cook_confirmed',
        isConfirmedByCook: true,
      ),
    ],
    allergenWarnings: const [
      OfferAllergenWarning(
        code: 'gluten',
        name: 'Gluten con texto largo para prueba',
        ingredientName: 'Harina integral de trigo con descripción larga',
        type: OfferAllergenWarningType.contains,
      ),
    ],
  );
}

DishPublication _longTextPublication() {
  return const DishPublication(
    id: 'publication-1',
    title:
        'Empanadas integrales rellenas de queso artesanal con nombre extremadamente largo',
    description:
        'Descripción larga usada para comprobar que la tarjeta conserva límites visuales.',
    price: 10,
    availableQuantity: 20,
    isActive: true,
    photos: [],
  );
}

ConsumerRequest _longTextRequest() {
  return ConsumerRequest(
    id: 'request-1',
    queryText:
        'empanadas integrales de queso con una descripción excesivamente larga para una solicitud',
    targetPrice: 120,
    requestedQuantity: 12,
    createdAt: DateTime(2026, 5, 21),
  );
}
