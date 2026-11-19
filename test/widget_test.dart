import 'package:flutter_test/flutter_test.dart';
import 'package:paragraf_do_kapsy/main.dart';
import 'package:paragraf_do_kapsy/state/app_state.dart';
import 'package:paragraf_do_kapsy/widgets/app_logo_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders dashboard with contracts and navigation', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(ParagrafApp(appState: appState));
    await tester.pumpAndSettle();

    // Verify title and header
    expect(find.text('Paragraf v kapse'), findsWidgets);
    expect(find.byType(AppLogoAction), findsWidgets);

    // Verify fast launcher actions
    expect(find.text('Kontrola smlouvy'), findsWidgets);
    expect(find.text('Mzdová kalkulačka'), findsWidgets);

    // Verify sample contracts from visual mockup
    expect(find.text('Software Tester'), findsOneWidget);
    expect(find.text('Junior Developer'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Smlouvy'), findsOneWidget);
    expect(find.text('Vysvětlivky'), findsOneWidget);
    expect(find.text('Kalkulačka'), findsOneWidget);

    // Tap on Kalkulačka tab in bottom navigation
    await tester.tap(find.text('Kalkulačka'));
    await tester.pumpAndSettle();

    // Verify Calculator Screen is rendered
    expect(find.text('Mzdová Kalkulačka'), findsOneWidget);
    expect(find.text('Zadání příjmu'), findsOneWidget);
    expect(find.text('ČISTÝ VÝDĚLEK NA ÚČET'), findsOneWidget);

    // Tap on Vysvětlivky tab in bottom navigation
    await tester.tap(find.text('Vysvětlivky'));
    await tester.pumpAndSettle();

    // Verify Explanations Screen is rendered
    expect(find.text('Právní vysvětlivky & Videa'), findsOneWidget);
    expect(find.text('Místo výkonu práce'), findsOneWidget);
    expect(find.text('Zkušební doba'), findsOneWidget);
  });
}
