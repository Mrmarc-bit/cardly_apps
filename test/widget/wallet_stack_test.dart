import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cardly/core/widgets/cardly_wallet_stack.dart';
import 'package:cardly/features/cards/domain/card_model.dart';
import 'package:cardly/core/widgets/cardly_visual_card.dart';

void main() {
  final sampleCards = [
    CardItem(
      id: 'card-1',
      nickname: 'BCA Everyday',
      issuer: 'Bank Central Asia',
      lastFourDigits: '4821',
      category: CardCategory.pembayaran,
      colorTheme: CardColorTheme.black,
      holderName: 'ADA LOVELACE',
      expiryDate: DateTime(2029, 9, 1),
    ),
    CardItem(
      id: 'card-2',
      nickname: 'Mandiri Platinum',
      issuer: 'Bank Mandiri',
      lastFourDigits: '9120',
      category: CardCategory.pembayaran,
      colorTheme: CardColorTheme.lime,
      holderName: 'ADA LOVELACE',
      expiryDate: DateTime(2028, 5, 1),
    ),
    CardItem(
      id: 'card-3',
      nickname: 'Jenius Debit',
      issuer: 'BTPN',
      lastFourDigits: '0917',
      category: CardCategory.pembayaran,
      colorTheme: CardColorTheme.gray,
      holderName: 'ADA LOVELACE',
      expiryDate: DateTime(2027, 12, 1),
    ),
  ];

  testWidgets('CardlyWalletStack renders cards in stack and expands upon tap', (
    WidgetTester tester,
  ) async {
    CardItem? tappedCard;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CardlyWalletStack(
              cards: sampleCards,
              onCardTap: (c) => tappedCard = c,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial header and card count
    expect(find.text('3 Kartu dalam Dompet'), findsOneWidget);
    expect(find.text('Ketuk kartu'), findsOneWidget);
    expect(find.text('BCA Everyday'), findsOneWidget);
    expect(find.text('Mandiri Platinum'), findsOneWidget);
    expect(find.text('Jenius Debit'), findsOneWidget);

    // Tap on the first card to lift it up
    await tester.tap(find.text('BCA Everyday'));
    await tester.pumpAndSettle();

    // Verify card is now expanded
    expect(find.text('Kartu 1 dari 3 Terpilih'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    expect(find.text('Buka Detail ↗'), findsOneWidget);
    expect(find.text('Tutup Tumpukan'), findsOneWidget);

    // Tap detail action
    await tester.tap(find.text('Lihat Detail ↗').first);
    expect(tappedCard?.id, equals('card-1'));

    // Tap Tutup to tuck back into stack
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    // Back to idle stack
    expect(find.text('3 Kartu dalam Dompet'), findsOneWidget);
    expect(find.text('Ketuk kartu'), findsOneWidget);
  });

  testWidgets(
    'CardlyWalletStack adapts cleanly to narrow 360dp mobile viewports',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardlyWalletStack(cards: sampleCards),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
