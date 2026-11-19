import '../models/law_explanation_model.dart';

class LawDataService {
  LawDataService._();

  static const List<LawExplanation> explanations = [
    LawExplanation(
      id: 'misto_vykonu',
      title: 'Místo výkonu práce',
      statuteRef: '§ 34 odst. 1 písm. b) Zákoníku práce',
      shortStatute: '§ 34 odst. 1 písm. b)',
      category: 'Povinné náležitosti',
      practicalMeaning:
          'Místo výkonu práce stanovuje, kde má zaměstnanec práci vykonávat. Pokud je sjednáno příliš široce (např. celá ČR), může zaměstnavatel zaměstnance vysílat na cesty bez zvláštního souhlasu a bez nároku na cestovní náhrady.',
      employerTrick:
          'Zaměstnavatelé často uvádějí celou ČR namísto konkrétního města, aby si zajistili maximální flexibilitu bez nutnosti sjednávat dodatky ke smlouvě.',
      fullStatuteText:
          'Pracovní smlouva musí obsahovat druh práce, místo nebo místa výkonu práce a den nástupu do práce.',
      videoTitle: 'Proč je „místo výkonu celá ČR“ past na zaměstnance?',
      videoDuration: '3:24 min',
      videoThumbnailUrl: '',
      youtubeUrl: 'https://www.youtube.com',
      safeClauseSuggestion:
          'Místem výkonu práce je sídlo zaměstnavatele na adrese: [Konkrétní adresa pracoviště].',
    ),
    LawExplanation(
      id: 'druh_prace',
      title: 'Druh práce',
      statuteRef: '§ 34 odst. 1 písm. a) Zákoníku práce',
      shortStatute: '§ 34 odst. 1 písm. a)',
      category: 'Povinné náležitosti',
      practicalMeaning:
          'Přesně vymezuje okruh činností, které po vás může zaměstnavatel požadovat. Příliš široká definice umožňuje přidělovat práci neodpovídající původní dohodě.',
      employerTrick:
          'Obecné formulace jako „pomocné administrativní práce všeho druhu“ dávají firmě prostor přidělovat jakékoliv úkoly.',
      fullStatuteText:
          'Pracovní smlouva musí obsahovat druh práce, který má zaměstnanec pro zaměstnavatele vykonávat.',
      videoTitle: 'Jak správně vymezit druh práce ve smlouvě',
      videoDuration: '2:45 min',
      videoThumbnailUrl: '',
      youtubeUrl: 'https://www.youtube.com',
      safeClauseSuggestion:
          'Druh práce: [Přesný název pozice] s rámcovou náplní uvedenou v popisu pracovní pozice.',
    ),
    LawExplanation(
      id: 'den_nastupu',
      title: 'Den nástupu do práce',
      statuteRef: '§ 34 odst. 1 písm. c) Zákoníku práce',
      shortStatute: '§ 34 odst. 1 písm. c)',
      category: 'Povinné náležitosti',
      practicalMeaning:
          'Dnem nástupu oficiálně vzniká pracovní poměr, i kdyby připadl na víkend či svátek. Od tohoto dne vznikají všechna práva a povinnosti.',
      employerTrick:
          'Podmiňování data nástupu dodatečnými podmínkami bez pevného data.',
      fullStatuteText:
          'Pracovní smlouva musí obsahovat den nástupu do práce.',
      videoTitle: 'Vznik pracovního poměru a den nástupu',
      videoDuration: '2:10 min',
      videoThumbnailUrl: '',
      youtubeUrl: 'https://www.youtube.com',
      safeClauseSuggestion:
          'Den nástupu do práce je sjednán na den: [DD. MM. RRRR].',
    ),
    LawExplanation(
      id: 'zkusebni_doba',
      title: 'Zkušební doba',
      statuteRef: '§ 35 Zákoníku práce',
      shortStatute: '§ 35',
      category: 'Doplňková ujednání',
      practicalMeaning:
          'Zkušební doba může trvat maximálně 3 měsíce (resp. 6 měsíců u vedoucích). Musí být sjednána písemně nejpozději v den nástupu do práce. Dodatečně ji nelze sjednat ani prodloužit.',
      employerTrick:
          'Sjednávání zkušební doby až po několika odpracovaných týdnech nebo její jednostranné prodlužování.',
      fullStatuteText:
          'Zkušební dobu je možné sjednat nejvýše na dobu 3 měsíců po sobě jdoucích ode dne vzniku pracovního poměru.',
      videoTitle: 'Zkušební doba: pravidla, limity a okamžité zrušení',
      videoDuration: '4:15 min',
      videoThumbnailUrl: '',
      youtubeUrl: 'https://www.youtube.com',
      safeClauseSuggestion:
          'Sjednává se zkušební doba v délce 3 měsíců ode dne vzniku pracovního poměru.',
    ),
    LawExplanation(
      id: 'konkurencni_dolozka',
      title: 'Konkurenční doložka',
      statuteRef: '§ 310 Zákoníku práce',
      shortStatute: '§ 310',
      category: 'Doplňková ujednání',
      practicalMeaning:
          'Zákaz činnosti u konkurence po skončení práce je platný pouze tehdy, pokud zaměstnavatel poskytuje peněžité vyrovnání ve výši nejméně 50 % průměrného měsíčního výdělku za každý měsíc omezení.',
      employerTrick:
          'Ujednání zákazu práce u konkurence bez jakéhokoliv peněžitého vyrovnání pod hrozbou smluvní pokuty.',
      fullStatuteText:
          'Dohodou se zaměstnanec zavazuje, že po určitou dobu, nejdéle 1 rok, se zdrží výkonu výdělečné činnosti pro konkurenci, a zaměstnavatel se zavazuje k přiměřenému peněžitému vyrovnání, nejméně 50 % průměrného měsíčního výdělku.',
      videoTitle: 'Jak se bránit neplatné konkurenční doložce',
      videoDuration: '3:50 min',
      videoThumbnailUrl: '',
      youtubeUrl: 'https://www.youtube.com',
      safeClauseSuggestion:
          'Konkurenční doložka se nesjednává / nebo se sjednává s kompenzací min. 50 % průměrného výdělku.',
    ),
    LawExplanation(
      id: 'limity_dpp_dpc',
      title: 'Zákonné limity pro DPP a DPČ',
      statuteRef: '§ 75 a § 76 Zákoníku práce',
      shortStatute: '§ 75 a § 76',
      category: 'Dohody',
      practicalMeaning:
          'DPP je omezena na maximálně 300 hodin v kalendářním roce u jednoho zaměstnavatele. DPČ umožňuje v průměru maximálně 20 hodin týdně (polovinu týdenní pracovní doby).',
      employerTrick:
          'Tlak na práci přes 300 hodin ročně bez evidence nebo nucení do neformální práce.',
      fullStatuteText:
          'Rozsah práce na základě dohody o provedení práce nesmí být větší než 300 hodin v kalendářním roce. Na základě dohody o pracovní činnosti nelze vykonávat práci v rozsahu překračujícím v průměru polovinu stanovené týdenní pracovní doby.',
      videoTitle: 'Novinky pro dohodáře: limity hodin a odvody',
      videoDuration: '4:02 min',
      videoThumbnailUrl: '',
      youtubeUrl: 'https://www.youtube.com',
      safeClauseSuggestion:
          'Rozsah práce na DPP nepřekročí 300 hodin v kalendářním roce.',
    ),
  ];

  static LawExplanation? getById(String id) {
    try {
      return explanations.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
