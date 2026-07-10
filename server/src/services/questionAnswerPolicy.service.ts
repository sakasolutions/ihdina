import type {
  QuestionMode,
  QuestionRoute,
} from "./questionRouter.service.js";

export type FollowUpAnswerPolicy = {
  primaryMode: QuestionMode;
  useContextWindow: boolean;
  fixedResponse: string | null;
  modelInstructions: string;
};

/**
 * Diese Regeln gelten für jede Modellantwort.
 *
 * Der konkrete Vers und – falls nötig – das Kontextfenster werden später
 * serverseitig aus quran-context.json ergänzt.
 */
const BASE_MODEL_INSTRUCTIONS = `
Allgemeine Regeln:
- Erkläre nur auf Grundlage des verifizierten Verskontexts und – sofern bereitgestellt – des angebundenen Tafsir-Auszuges.
- Erfinde keine historischen Hintergründe, Offenbarungsanlässe, Tafsir-Meinungen, Hadithe, Gelehrtenzitate oder Quellen.
- Wenn ein angebundener Tafsir-Auszug vorhanden ist, darfst du ihn nutzen. Formuliere dann klar als „Der angebundene Tafsir erklärt ...“ oder „Im angebundenen Tafsir wird ...“.
- Der angebundene Tafsir ist Erklärungskontext, aber keine Fatwa für persönliche Einzelfälle.
- Behaupte nicht, Ibn Kathir oder andere Gelehrte hätten etwas Bestimmtes erklärt, wenn kein geprüfter Quellentext bereitgestellt wurde.
- Formuliere textnah, ruhig, respektvoll und verständlich auf Deutsch.
- Verwende standardmäßig „Allah“ als Bezeichnung für den Schöpfer. Schreibe nicht „Gott“, außer in direkten Zitaten aus bereitgestelltem Text.
- Überdehne den Wortlaut nicht zu einer stärkeren Aussage. Wenn die Übersetzung „mit der Erschwernis“ sagt, formuliere nicht pauschal „nach jeder Schwierigkeit“, „immer“, „garantiert“ oder als direkte persönliche Zusage.
- Wenn der bereitgestellte Vers eine Gleichzeitigkeit oder Verbindung ausdrückt, zum Beispiel „mit“, ersetze das nicht durch eine zeitliche Reihenfolge wie „nach“, „danach“, „folgt“, „kommt nach“ oder „wird folgen“.
- Behaupte nicht, Schwierigkeiten seien generell „nicht dauerhaft“, wenn das nicht ausdrücklich im bereitgestellten Vers steht.
- Unterscheide zwischen allgemeiner Reflexion und konkreter persönlicher Garantie.
- Mache keine persönlichen religiösen Zusagen wie „Allah wird dir helfen“, „Allah hat dich nicht verlassen“, „du kannst das sicher tragen“ oder „deine Prüfung hat einen bestimmten Sinn“.
- Entscheide nicht über Allahs Urteil über eine konkrete Person, ihren Glauben, ihre Schuld oder ihren religiösen Wert.
- Antworte ohne pauschalen KI-Disclaimer am Ende. Begrenze stattdessen direkt dort, wo der konkrete Fall eine Grenze verlangt.
`.trim();

const FIXED_RESPONSES: Partial<Record<QuestionMode, string>> = {
  safety:
    "Bei Gewalt, Drohungen, Zwang oder akuter Unsicherheit steht deine Sicherheit zuerst. Ich kann nicht helfen, Gewalt religiös zu rechtfertigen oder zu relativieren. Bring dich bei Gefahr an einen sicheren Ort, kontaktiere eine vertrauenswürdige Person oder professionelle Hilfe vor Ort. Bei unmittelbarer Gefahr ruf bitte die lokale Notrufnummer an.",

  fiqhOrPersonalCase:
    "Der bereitgestellte Vers kann ein Thema allgemein erwähnen. Ihdina entscheidet aber keinen konkreten religiös-rechtlichen Einzelfall und gibt keine Aussage über Erlaubnis, Pflicht, Gültigkeit, Ungültigkeit oder Sünde. Für die konkrete Anwendung sollte eine qualifizierte, vertrauenswürdige religiöse Anlaufstelle gefragt werden. Wenn die Frage Gesundheit betrifft, sollte zusätzlich medizinisches Fachpersonal einbezogen werden.",

  sourceOrHadith:
    "Für Tafsir-Erklärungen ist ein angebundener Tafsir-Kontext vorhanden. Für Hadithe, Sunnah-Aussagen, Authentizitätsgrade oder konkrete Aussagen anderer Gelehrter habe ich aktuell aber keinen separat verifizierten Quellenbestand. Deshalb möchte ich keine Überlieferung, Einstufung oder Gelehrtenaussage aus dem Gedächtnis wiedergeben. Quelle des angebundenen Tafsir-Kontexts: Tafsīr Al-Qur'ān Al-Karīm, Muhammad Ibn Ahmad Ibn Rassoul, IB Verlag, 41. Auflage, 2008.",

  adversarialOrProvocation:
    "Ich helfe dir gern, den Vers sachlich und respektvoll zu verstehen. Ich unterstütze aber nicht dabei, andere Menschen mit religiösen Argumenten zu demütigen, zu bedrängen oder in einer Debatte „zu besiegen“.",
};

function instructionsForMode(mode: QuestionMode): string {
  switch (mode) {
    case "normalVerse":
      return `
Normaler Versmodus:
- Erkläre die Kernaussage und die sichtbare Aussage des Verses.
- Eine heutige Einordnung darf allgemein bleiben, aber nicht in konkrete Lebensentscheidungen oder persönliche Zusagen übergehen.
- Bleibe beim vorliegenden Wortlaut und vermeide zusätzliche historische oder theologische Behauptungen.
      `.trim();

    case "context":
      return `
Kontextmodus:
- Nutze nur die bereitgestellten Nachbarverse, um „davor“, „danach“ oder den unmittelbaren Textzusammenhang zu erklären.
- Zähle die Nachbarverse nicht nur auf. Erkläre knapp, welche Beziehung sie zum ausgewählten Vers haben und wie sie den Abschnitt strukturieren.
- Arbeite den Mehrwert aus dem sichtbaren Text heraus: Wiederholung, Übergang, Gegenüberstellung, Aufforderung, Abschluss oder thematischer Zusammenhang.
- Unterscheide klar zwischen dem sichtbaren Zusammenhang im Kontextfenster und nicht bereitgestelltem historischem Hintergrund.
- Bei Fragen nach Offenbarungsanlass oder genauer historischer Situation: Sage offen, dass dies aus dem bereitgestellten Versfenster nicht zuverlässig bestimmt werden kann.
      `.trim();

    case "wordOrImage":
      return `
Wort- und Bildsprachemodus:
- Erkläre erkennbare Begriffe, Bilder und Formulierungen möglichst textnah.
- Behaupte keine grammatischen Feinheiten, Wortwurzeln oder arabischen Fachdetails, wenn sie nicht im bereitgestellten Material überprüfbar sind.
- Stelle sprachliche Deutungen als vorsichtige Einordnung dar, nicht als endgültige Tafsir-Aussage.
      `.trim();

    case "tafsirOrSource":
      return `
Tafsir- und Quellenmodus:
- Nutze den angebundenen Tafsir-Auszug, sofern er Inhalt enthält.
- Antworte nicht allgemein „die Gelehrten sagen“, sondern benenne nur den angebundenen Tafsir-Kontext.
- Wenn der Tafsir-Auszug leer ist, sage klar, dass für diesen Vers kein eigener Tafsir-Erläuterungstext im angebundenen Datensatz enthalten ist.
- Gib am Ende die Quelle des angebundenen Tafsir-Kontexts an.
- Keine Hadith-Einstufung, keine Authentizitätsbewertung und keine Aussagen aus anderen Tafsirwerken, wenn sie nicht bereitgestellt wurden.
      `.trim();

    case "fiqhOrPersonalCase":
      return `
Fiqh- und Einzelfallgrenze:
- Du darfst erklären, welches Thema der vorliegende Vers allgemein erwähnt.
- Entscheide aber keinen konkreten religiös-rechtlichen Einzelfall.
- Antworte bei Fragen wie „Darf ich ...?“, „Ist meine Waschung gültig?“, „Muss ich ...?“, „Ist es erlaubt ...?“ nicht mit Ja/Nein.
- Formuliere nicht „das bedeutet, dass es erlaubt ist“, „du darfst“, „es ist gültig“, „es ist ungültig“, „du musst“ oder vergleichbare rechtliche Schlussfolgerungen für den Nutzer.
- Sage stattdessen: „Der Vers erwähnt ...“ oder „Im bereitgestellten Vers steht ...“, und grenze dann ab, dass die konkrete Anwendung mit einer qualifizierten, vertrauenswürdigen religiösen Anlaufstelle geklärt werden sollte.
- Keine Halal-/Haram-Entscheidung, keine Aussage über Pflicht, Gültigkeit, Sünde, Scheidung, Fasten, Gebet, Wudu, Tayammum, Kredit, Zakat oder vergleichbare persönliche Fälle.
      `.trim();

    case "medicalOrMentalHealth":
      return `
Gesundheit- und psychische-Belastung-Grenze:
- Erkläre den Vers nur allgemein und ohne Diagnose.
- Keine medizinische, therapeutische oder medikamentöse Anweisung.
- Keine Aussage darüber, ob eine Person religiös entschuldigt, schuldig, „schlecht“ oder von Allah bestraft ist.
- Bei relevanter Belastung: Ermutige sachlich dazu, zeitnah medizinische oder psychologische Hilfe einzubeziehen; bei religiöser Einzelfrage zusätzlich eine qualifizierte religiöse Anlaufstelle.
      `.trim();

    case "aqidaOrControversy":
      return `
Aqida- und Kontroversenmodus:
- Erkläre zunächst den sichtbaren Wortlaut des vorliegenden Verses.
- Stelle keine vollständige Glaubenslehre, endgültige Dogmatik oder interreligiöse „Beweisführung“ aus einem Einzelvers her.
- Keine absolute Behauptung, dass eine komplexe theologische Frage durch diesen einen Vers endgültig entschieden sei.
- Formuliere verschiedene mögliche Lesarten nur vorsichtig und ohne erfundene Quellen- oder Gelehrtenverweise.
      `.trim();

    case "safety":
    case "sourceOrHadith":
    case "adversarialOrProvocation":
      return "";

    default: {
      const exhaustiveCheck: never = mode;
      return exhaustiveCheck;
    }
  }
}

function isFixedResponseMode(mode: QuestionMode): boolean {
  return Object.prototype.hasOwnProperty.call(FIXED_RESPONSES, mode);
}

/**
 * Erzeugt die sichere Antwortstrategie für eine klassifizierte Folgefrage.
 *
 * Safety, Quellen- und Provokationsfälle erhalten vorerst eine feste Antwort,
 * damit das Modell weder Gewalt noch Quellenangaben aus dem Gedächtnis erzeugt.
 */
export function getFollowUpAnswerPolicy(
  route: QuestionRoute
): FollowUpAnswerPolicy {
  const fixedResponse =
    FIXED_RESPONSES[route.primaryMode] ??
    (route.matchedModes.includes("fiqhOrPersonalCase")
      ? FIXED_RESPONSES.fiqhOrPersonalCase ?? null
      : null);

  if (fixedResponse) {
    return {
      primaryMode: route.primaryMode,
      useContextWindow: false,
      fixedResponse,
      modelInstructions: "",
    };
  }

  const applicableModes = route.matchedModes.filter(
    (mode) => !isFixedResponseMode(mode)
  );

  const modeInstructions = applicableModes
    .map(instructionsForMode)
    .filter((instruction) => instruction.length > 0)
    .join("\n\n");

  return {
    primaryMode: route.primaryMode,
    useContextWindow: route.matchedModes.includes("context"),
    fixedResponse: null,
    modelInstructions: `${BASE_MODEL_INSTRUCTIONS}\n\n${modeInstructions}`.trim(),
  };
}
