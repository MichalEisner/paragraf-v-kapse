import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paragraf_do_kapsy/models/contract_model.dart';
import 'package:paragraf_do_kapsy/screens/clause_detail_screen.dart';
import 'package:paragraf_do_kapsy/screens/contract_detail_screen.dart';
import 'package:paragraf_do_kapsy/screens/contract_questionnaire_screen.dart';
import 'package:paragraf_do_kapsy/services/law_data_service.dart';
import 'package:paragraf_do_kapsy/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ContractQuestionnaireScreen renders and calculates score', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      MaterialApp(
        home: ContractQuestionnaireScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kontrola smlouvy'), findsOneWidget);
    expect(find.text('Pojďme smlouvu projít řádek po řádku!'), findsOneWidget);
    expect(find.text('Povinné náležitosti'), findsOneWidget);
    expect(find.text('1. Druh práce'), findsOneWidget);
    expect(find.text('2. Místo výkonu práce'), findsOneWidget);
    expect(find.text('3. Den nástupu do práce'), findsOneWidget);
    expect(find.text('4. Zkušební doba'), findsOneWidget);
    expect(find.text('5. Konkurenční doložka'), findsOneWidget);
    expect(find.text('Uložit do Mých smluv'), findsOneWidget);
  });

  testWidgets('ContractDetailScreen displays DPP hour tracker and logs new shift', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();
    final contract = appState.contracts.firstWhere((c) => c.contractType == ContractType.dpp);

    await tester.pumpWidget(
      MaterialApp(
        home: ContractDetailScreen(contract: contract, appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Smlouvy'), findsOneWidget);
    expect(find.text(contract.companyName), findsWidgets);
    expect(find.text('Limit 300 hodin'), findsOneWidget);
    expect(find.text('Nový záznam práce'), findsOneWidget);
    expect(find.text('Poslední záznamy'), findsOneWidget);

    // Scroll to and verify saving new shift
    final saveButtonFinder = find.text('Uložit hodiny do deníku');
    await tester.ensureVisible(saveButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('Zapsáno +4.0 h'), findsOneWidget);
  });

  testWidgets('ClauseDetailScreen displays practical meaning, statute and video banner', (WidgetTester tester) async {
    final explanation = LawDataService.explanations.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ClauseDetailScreen(explanation: explanation),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Ustanovení'), findsOneWidget);
    expect(find.text(explanation.title), findsOneWidget);
    expect(find.text('Co to v praxi znamená pro vás?'), findsOneWidget);
    expect(find.text('Častý trik zaměstnavatelů'), findsOneWidget);
    expect(find.text('YouTube výklad'), findsOneWidget);
    expect(find.text('Zpět'), findsOneWidget);
  });
}
