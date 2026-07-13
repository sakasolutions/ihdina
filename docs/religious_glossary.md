# Religiöses Glossar

## Zweck

Das Glossar soll:

- arabische und türkisch geprägte Fachbegriffe für deutschsprachige Nutzer verständlich erklären
- kurze, einfache Erklärungen für die App bereitstellen
- eine genauere interne fachliche Einordnung dokumentieren
- Begriffe mit den verwendeten Quellen verknüpfen
- deutlich machen, wann eine allgemeine Erklärung nicht für eine individuelle Beurteilung ausreicht
- keine persönliche Fatwa oder medizinische Diagnose ermöglichen

---

## Grundprinzip

Ihdina:

- erklärt allgemeine hanafitische Begriffe und Regeln
- stützt sich auf klar benannte Quellen
- formuliert Inhalte eigenständig auf Deutsch
- bestimmt nicht automatisch, welche konkrete Flüssigkeit, Blutung oder persönliche Situation bei einem Nutzer vorliegt
- gibt keine individuelle Rechtsentscheidung
- verweist bei Unsicherheit auf eine qualifizierte hanafitische Fachperson oder einen vertrauenswürdigen Gelehrten
- verweist bei medizinischen Beschwerden zusätzlich auf medizinisches Fachpersonal

---

## Verbindlicher Transparenzhinweis

Dieser Hinweis soll in der Dokumentation festgehalten und später bei sensiblen Glossarbegriffen sichtbar gemacht werden:

> **Wichtiger Hinweis**
>
> Diese Erklärung beschreibt eine allgemeine hanafitische Einordnung. Sie kann keine individuelle Beurteilung ersetzen.
>
> Wenn du nicht sicher bist, welcher Begriff auf deine Situation zutrifft, frage eine qualifizierte hanafitische Fachperson oder einen vertrauenswürdigen Gelehrten. Bei medizinischen Beschwerden solltest du zusätzlich medizinisches Fachpersonal hinzuziehen.

---

# Struktur jedes Glossareintrags

Jeder Eintrag soll folgende Felder enthalten:

- **ID**
- **Begriff**
- **Arabisch**
- **Alternative Schreibweisen**
- **Einfache Erklärung**
- **Fachliche Einordnung**
- **Bedeutung für Wudu oder Ghusl**
- **Was die App nicht entscheiden darf**
- **Wann eine Fachperson gefragt werden sollte**
- **Quellen**
- **Prüfstatus**
- **Vorgesehene Darstellung in der App**

---

## Vorgesehene App-Darstellung

Bei erstmaligem Auftreten eines Fachbegriffs:

- deutschen Begriff zuerst verwenden
- Fachbegriff in Klammern ergänzen
- Fachbegriff visuell markieren
- Begriff antippbar machen

**Beispiel:** „Zustand großer ritueller Unreinheit (**Janāba**)“

Beim Antippen öffnet sich ein Bottom Sheet mit:

1. Begriff
2. kurze einfache Erklärung
3. Auswirkung auf Wudu oder Ghusl
4. Quellen
5. Hinweis bei Unsicherheit

Keine langen Fiqh-Abhandlungen im Popup.

---

# Glossareinträge

## 1. Wudu

- **ID:** glossary_wudu
- **Begriff:** Wudu
- **Arabisch:** وُضُوء
- **Alternative Schreibweisen:** Wuḍūʾ, Wudū, Gebetswaschung
- **Einfache Erklärung:** Die rituelle Waschung, die unter anderem für das Gebet erforderlich ist.
- **Fachliche Einordnung:** Wudu beseitigt den Zustand der kleinen rituellen Unreinheit.
- **Bedeutung für Wudu oder Ghusl:** Wudu ersetzt keinen erforderlichen Ghusl.
- **Was die App nicht entscheiden darf:** Ob ein konkreter Sonderfall den Wudu tatsächlich aufgehoben hat.
- **Wann Fachperson fragen:** Bei Blutungen, chronischen Austritten, unklaren Schlafsituationen oder anderen Grenzfällen.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, Abschnitt „Abdest“, ab S. 96
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet gemäß UX-Konzept

---

## 2. Ghusl

- **ID:** glossary_ghusl
- **Begriff:** Ghusl
- **Arabisch:** غُسْل
- **Alternative Schreibweisen:** Gusl, Gusül, Ganzkörperwaschung
- **Einfache Erklärung:** Die rituelle Ganzkörperwaschung, durch die ein Zustand großer ritueller Unreinheit aufgehoben wird.
- **Fachliche Einordnung:** Ghusl wird in bestimmten Situationen verpflichtend, etwa nach Geschlechtsverkehr, einem relevanten Austritt von Samenflüssigkeit oder nach dem Ende von Menstruation und Wochenbettblutung.
- **Bedeutung für Wudu oder Ghusl:** Wenn Ghusl erforderlich ist, reicht Wudu allein für das Gebet nicht aus.
- **Was die App nicht entscheiden darf:** Ob eine konkrete Flüssigkeit, Blutung oder persönliche Situation sicher Ghusl erforderlich macht.
- **Wann Fachperson fragen:** Bei Unsicherheit über Flüssigkeiten, Blutungsverläufe, medizinische Umstände oder Grenzfälle.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „Gusül“, S. 119–123
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification, Kapitel zu Ghusl
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet gemäß UX-Konzept

---

## 3. Janāba

- **ID:** glossary_janaba
- **Begriff:** Janāba
- **Arabisch:** جَنَابَة
- **Alternative Schreibweisen:** Dschanāba, Janaba, Cünüplük
- **Einfache Erklärung:** Der Zustand großer ritueller Unreinheit, in dem Ghusl erforderlich ist.
- **Fachliche Einordnung:** Dieser Zustand kann unter anderem nach Geschlechtsverkehr oder dem relevanten Austritt von Samenflüssigkeit entstehen.
- **Bedeutung für Wudu oder Ghusl:** Ein gewöhnlicher Wudu allein hebt Janāba nicht auf.
- **Was die App nicht entscheiden darf:** Ob ein konkreter Ausfluss oder eine konkrete Situation sicher Janāba ausgelöst hat.
- **Wann Fachperson fragen:** Bei Unsicherheit über Flüssigkeiten, feuchte Träume, Restflüssigkeiten oder ungewöhnliche Situationen.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, S. 119–121
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification, Kapitel zu Ghusl
  - Nūr al-Īḍāḥ verwendet „janaba“ als Bezeichnung für den Zustand großer ritueller Unreinheit.
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrtenhinweis

---

## 4. Cünüp

- **ID:** glossary_cunup
- **Begriff:** Cünüp
- **Arabisch:** جُنُب
- **Alternative Schreibweisen:** Junub
- **Einfache Erklärung:** Türkischer und teilweise im deutschsprachigen muslimischen Alltag gebräuchlicher Ausdruck für eine Person im Zustand der Janāba.
- **Fachliche Einordnung:** Der Begriff bezeichnet keinen eigenen zusätzlichen Zustand, sondern eine Person, für die aufgrund von Janāba Ghusl erforderlich ist.
- **Bedeutung für Wudu oder Ghusl:** Wudu allein reicht in diesem Zustand nicht aus.
- **Was die App nicht entscheiden darf:** Ob eine Person aufgrund einer konkreten Situation sicher als cünüp gilt.
- **Wann Fachperson fragen:** Bei Unsicherheit über Flüssigkeiten oder den Zustand der rituellen Reinheit.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, S. 119–123
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Verweis auf Eintrag Janāba

---

## 5. Manī

- **ID:** glossary_mani
- **Begriff:** Manī
- **Arabisch:** مَنِيّ
- **Alternative Schreibweisen:** Mani, Menī, Samenflüssigkeit
- **Einfache Erklärung:** Die Flüssigkeit, deren relevanter Austritt unter den hanafitisch beschriebenen Voraussetzungen Ghusl erforderlich machen kann.
- **Fachliche Einordnung:** Diyanet beschreibt den mit sexueller Erregung verbundenen Austritt von Samenflüssigkeit als einen Auslöser für Janāba und Ghusl. Die Regel betrifft Männer und Frauen. Deshalb nicht ausschließlich den Begriff „Sperma“ verwenden.
- **Bedeutung für Wudu oder Ghusl:** Ein relevanter Austritt kann Ghusl erforderlich machen.
- **Was die App nicht entscheiden darf:** Die App darf eine vom Nutzer bemerkte Flüssigkeit nicht automatisch als Manī bestimmen.
- **Wann Fachperson fragen:** Wenn unklar ist, um welche Flüssigkeit es sich handelt, ob sexuelle Erregung vorlag oder ob ein Sonderfall besteht.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, S. 120
  - Relevante Aussagen: Austritt von Samenflüssigkeit im Zusammenhang mit sexueller Erregung; Entstehung von Janāba; Ghusl wird erforderlich
  - Diyanet unterscheidet Manī ausdrücklich von Mezi und Vedi
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Kapitel zu Ghusl *(genaue Seite offen)*
- **Prüfstatus:** Diyanet dokumentiert – Nūr-al-Īḍāḥ-Seite offen – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrtenhinweis

---

## 6. Madhy

- **ID:** glossary_madhy
- **Begriff:** Madhy
- **Arabisch:** مَذْي
- **Alternative Schreibweisen:** Madhī, Mazi, Mezi, Lusttropfen
- **Einfache Erklärung:** Eine dünne Flüssigkeit, die im Zusammenhang mit sexueller Erregung austreten kann, ohne dass es zu einem Samenerguss kommt.
- **Fachliche Einordnung:** Diyanet beschreibt Mezi als eine dünne Flüssigkeit, deren Austritt keinen Ghusl erforderlich macht, aber Wudu aufhebt.
- **Bedeutung für Wudu oder Ghusl:**
  - Ghusl allein wegen Madhy: grundsätzlich nein
  - Wudu: wird erneuert
  - betroffene Stelle: muss gereinigt werden
- **Was die App nicht entscheiden darf:** Die App darf nicht anhand weniger Merkmale sicher feststellen, dass eine konkrete Flüssigkeit Madhy ist.
- **Wann Fachperson fragen:** Wenn die Flüssigkeit nicht eindeutig zugeordnet werden kann oder wiederholt beziehungsweise krankheitsbedingt auftritt.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, S. 120
  - Relevante Aussage: Mezi erfordert keinen Ghusl, hebt aber Wudu auf
  - Nūr al-Īḍāḥ *(genaue Fundstelle offen)*
- **Sprachregel:** „Lusttropfen“ kann als alltagssprachliche Orientierung genannt werden, darf aber nicht als medizinische Diagnose verwendet werden.
- **Prüfstatus:** Diyanet dokumentiert – Nūr-al-Īḍāḥ-Seite offen – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrtenhinweis

---

## 7. Wady

- **ID:** glossary_wady
- **Begriff:** Wady
- **Arabisch:** وَدْي
- **Alternative Schreibweisen:** Wadī, Wadi, Vedi
- **Einfache Erklärung:** Eine dicklich-trübe Flüssigkeit, die häufig nach dem Wasserlassen austreten kann und nicht als Samenflüssigkeit gilt.
- **Fachliche Einordnung:** Diyanet beschreibt Vedi als eine dicke und trübe Flüssigkeit, die nach dem Wasserlassen austreten kann.
- **Bedeutung für Wudu oder Ghusl:**
  - Ghusl allein wegen Wady: nein
  - Wudu: wird durch den Austritt ungültig
  - betroffene Stelle: reinigen
- **Was die App nicht entscheiden darf:** Die App darf eine konkrete Flüssigkeit nicht automatisch als Wady bestimmen.
- **Wann Fachperson fragen:** Bei unklarer Flüssigkeit, Schmerzen, ungewöhnlicher Farbe, wiederkehrendem Austritt oder medizinischen Beschwerden.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, S. 120
  - Relevante Aussage: Vedi erfordert keinen Ghusl
  - asch-Schurunbulālī, Nūr al-Īḍāḥ *(genaue Fundstelle offen)*
- **Offener Prüfpunkt:** Die Aussage, dass Wady Wudu aufhebt, vor Veröffentlichung zusätzlich mit der konkreten Nūr-al-Īḍāḥ-Stelle beziehungsweise einem zweiten hanafitischen Beleg dokumentieren.
- **Prüfstatus:** Diyanet dokumentiert – Nūr-al-Īḍāḥ-Seite offen – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrten- und medizinischem Hinweis

---

## 8. Feuchter Traum

- **ID:** glossary_wet_dream
- **Begriff:** Feuchter Traum
- **Arabisch:** اِحْتِلَام
- **Alternative Schreibweisen:** Iḥtilām, ihtilam
- **Einfache Erklärung:** Ein sexueller Traum während des Schlafs.
- **Fachliche Einordnung:** Der Traum allein macht Ghusl nicht automatisch erforderlich. Entscheidend ist, ob nach dem Aufwachen eine entsprechende Flüssigkeit festgestellt wird.
- **Bedeutung für Wudu oder Ghusl:**
  - Traum mit festgestellter entsprechender Flüssigkeit: Ghusl kann erforderlich sein
  - bloße Erinnerung an einen Traum ohne festgestellte Flüssigkeit: Ghusl nicht allein wegen des Traums erforderlich
- **Was die App nicht entscheiden darf:** Welche Flüssigkeit festgestellt wurde und ob alle Voraussetzungen erfüllt sind.
- **Wann Fachperson fragen:** Bei unklarer Feuchtigkeit oder Unsicherheit über die Einordnung.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, S. 120
  - Relevante Aussagen: Erinnerung an einen Traum und festgestellte Feuchtigkeit; Feuchtigkeit ohne Erinnerung an den Traum; Traum ohne festgestellte Feuchtigkeit
  - Diyanet hält fest, dass allein ein Traum ohne festgestellte Flüssigkeit keinen Ghusl erforderlich macht
  - Nūr al-Īḍāḥ *(genaue Fundstelle offen)*
- **Prüfstatus:** Diyanet dokumentiert – Nūr-al-Īḍāḥ-Seite offen – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrtenhinweis

---

## 9. Hayd

- **ID:** glossary_hayd
- **Begriff:** Hayd
- **Arabisch:** حَيْض
- **Alternative Schreibweisen:** Ḥayḍ, Haid, Menstruation, Regelblutung
- **Einfache Erklärung:** Der fiqhrechtliche Begriff für die Menstruationsblutung.
- **Fachliche Einordnung:** Hayd wird von unregelmäßigen oder krankheitsbedingten Blutungen unterschieden.
- **Bedeutung für Wudu oder Ghusl:** Nach dem vollständigen Ende der Menstruation wird Ghusl erforderlich.
- **Was die App nicht entscheiden darf:** Ob eine konkrete Blutung sicher als Hayd gilt, wann sie begonnen oder vollständig geendet hat und wie unregelmäßige Verläufe zu beurteilen sind.
- **Wann Fachperson fragen:** Bei unregelmäßigen Blutungen, Unterbrechungen, Abweichungen vom üblichen Verlauf oder Unsicherheit über Beginn und Ende.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „Hayız“, ab S. 124
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification, S. 95 ff.
  - Nūr al-Īḍāḥ behandelt Hayd und dessen Abgrenzung zu Istihāda ausführlich
- **Wichtiger Hinweis:** Zeitgrenzen und Detailregeln nicht als eigenständige Selbstdiagnose im kurzen Glossar-Popup darstellen.
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrten- und medizinischem Hinweis

---

## 10. Nifās

- **ID:** glossary_nifas
- **Begriff:** Nifās
- **Arabisch:** نِفَاس
- **Alternative Schreibweisen:** Nifas, Wochenbettblutung, Lochien
- **Einfache Erklärung:** Die fiqhrechtlich relevante Blutung nach einer Geburt.
- **Fachliche Einordnung:** Nifās wird von anderen Blutungen nach einer Geburt beziehungsweise von Istihāda unterschieden.
- **Bedeutung für Wudu oder Ghusl:** Nach dem vollständigen Ende der Wochenbettblutung wird Ghusl erforderlich.
- **Was die App nicht entscheiden darf:** Ob ein konkreter Blutungsverlauf als Nifās oder als andere Blutung einzuordnen ist.
- **Wann Fachperson fragen:** Bei Unterbrechungen, ungewöhnlicher Dauer, fehlender sichtbarer Blutung, Fehlgeburt oder anderen besonderen Verläufen.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „Nifas“, ab S. 127
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification, S. 96 ff.
  - Nūr al-Īḍāḥ definiert Nifās als Blutung nach einer Geburt und behandelt die Abgrenzung zu Istihāda
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrten- und medizinischem Hinweis

---

## 11. Istihāda

- **ID:** glossary_istihada
- **Begriff:** Istihāda
- **Arabisch:** اِسْتِحَاضَة
- **Alternative Schreibweisen:** Istihada, Istihāḍa, unregelmäßige Blutung
- **Einfache Erklärung:** Eine Blutung, die fiqhrechtlich nicht als Menstruation oder Wochenbettblutung eingeordnet wird.
- **Fachliche Einordnung:** Istihāda folgt anderen Regeln als Hayd und Nifās.
- **Bedeutung für Wudu oder Ghusl:** Istihāda macht nicht automatisch nach jeder Feststellung einen neuen Ghusl erforderlich. Je nach Dauer und Verlauf können Regeln für entschuldigte Personen relevant werden.
- **Was die App nicht entscheiden darf:** Ob eine konkrete Blutung sicher Istihāda ist und welche individuellen Regeln daraus folgen.
- **Wann Fachperson fragen:** Bei jeder unklaren Abgrenzung zu Menstruation oder Wochenbettblutung, besonders bei lang anhaltenden oder wiederkehrenden Blutungen.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „İstihaze“, S. 128 ff.
  - Diyanet, „Özür Sahibi Olanların Durumu“, ab S. 131
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification, S. 95–98
  - Nūr al-Īḍāḥ grenzt Blutungen unterhalb beziehungsweise außerhalb der Menstruationsregeln als Istihāda ab
- **Wichtiger Hinweis:** Keine automatische Berechnung oder Einordnung allein anhand von Tagen veröffentlichen, bevor der gesamte Bereich fachlich geprüft wurde.
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrten- und medizinischem Hinweis

---

## 12. Kleine rituelle Unreinheit

- **ID:** glossary_minor_ritual_impurity
- **Begriff:** Kleine rituelle Unreinheit
- **Arabisch:** حَدَث أَصْغَر
- **Alternative Schreibweisen:** Hadath asghar
- **Einfache Erklärung:** Ein ritueller Zustand, der grundsätzlich durch Wudu aufgehoben wird.
- **Fachliche Einordnung:** Hadath asghar ist der Gegenbegriff zur großen rituellen Unreinheit.
- **Bedeutung für Wudu oder Ghusl:** Wudu ist hierfür grundsätzlich ausreichend, sofern nicht zusätzlich Ghusl erforderlich ist.
- **Was die App nicht entscheiden darf:** Ob ein konkreter Zustand sicher Hadath asghar ist oder ob zusätzlich Ghusl erforderlich ist.
- **Wann Fachperson fragen:** Bei Unsicherheit über den rituellen Zustand.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „Hadesten Taharet“, S. 90
  - Nūr al-Īḍāḥ, Book I – Purification
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet gemäß UX-Konzept

---

## 13. Große rituelle Unreinheit

- **ID:** glossary_major_ritual_impurity
- **Begriff:** Große rituelle Unreinheit
- **Arabisch:** حَدَث أَكْبَر
- **Alternative Schreibweisen:** Hadath akbar
- **Einfache Erklärung:** Ein ritueller Zustand, für dessen Aufhebung Ghusl erforderlich ist.
- **Fachliche Einordnung:** Hadath akbar umfasst unter anderem Janāba und den Zustand nach Menstruation und Wochenbettblutung.
- **Bedeutung für Wudu oder Ghusl:** Wudu allein reicht nicht aus.
- **Was die App nicht entscheiden darf:** Ob ein konkreter Zustand sicher Hadath akbar ist.
- **Wann Fachperson fragen:** Bei Unsicherheit über Flüssigkeiten, Blutungen oder den rituellen Zustand.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „Gusül“, S. 119–123
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet gemäß UX-Konzept

---

## 14. Tayammum

- **ID:** glossary_tayammum
- **Begriff:** Tayammum
- **Arabisch:** تَيَمُّم
- **Alternative Schreibweisen:** Teyemmüm
- **Einfache Erklärung:** Eine rituelle Ersatzreinigung mit geeignetem Erdmaterial, wenn Wasser nicht verfügbar ist oder nicht verwendet werden kann.
- **Fachliche Einordnung:** Tayammum unterliegt eigenen Voraussetzungen und darf nicht allein aus Bequemlichkeit gewählt werden.
- **Bedeutung für Wudu oder Ghusl:** Tayammum kann unter anerkannten Voraussetzungen Wudu oder Ghusl vorübergehend ersetzen.
- **Was die App nicht entscheiden darf:** Ob bei einer konkreten Krankheit, Verletzung oder Wassersituation Tayammum zulässig ist.
- **Wann Fachperson fragen:** Bei medizinischen Einschränkungen, unklarer Wasserverfügbarkeit oder Unsicherheit über die Voraussetzungen.
- **Quellen:**
  - Diyanet İşleri Başkanlığı, İslam İlmihali, „Teyemmüm“, S. 115–119
  - asch-Schurunbulālī, Nūr al-Īḍāḥ, Book I – Purification, Kapitel zu Tayammum
- **Prüfstatus:** dokumentiert – fachliche Endprüfung offen
- **Vorgesehene Darstellung in der App:** anklickbarer Begriff, Bottom Sheet mit Gelehrtenhinweis

---

# Schreib- und UX-Regeln

## Sprache

- zuerst verständliches Deutsch
- Fachbegriff anschließend in Klammern
- keine unnötige Ansammlung arabischer Begriffe
- keine medizinische Fachsprache, wenn sie nicht nötig ist
- keine beschämende oder wertende Sprache
- sachlich, ruhig und respektvoll

## Anklickbare Begriffe

Später antippbar:

- Wudu
- Ghusl
- Janāba
- Cünüp
- Manī
- Madhy
- Wady
- Iḥtilām
- Hayd
- Nifās
- Istihāda
- kleine rituelle Unreinheit
- große rituelle Unreinheit
- Tayammum

## Darstellung im Bottom Sheet

**Pflichtfelder:**

- einfacher Titel
- arabischer Begriff optional kleiner darunter
- „Einfach erklärt“
- „Was bedeutet das für Wudu oder Ghusl?“
- Quelle
- Gelehrtenhinweis bei sensiblen Begriffen

**Nicht anzeigen:**

- lange Meinungsunterschiede
- vollständige juristische Detaildebatten
- automatische Diagnosefragen
- Bilder von Körperflüssigkeiten
- KI-generierte Einzelfallentscheidung

---

# Quellenprinzip

Für jeden Glossareintrag dokumentieren:

1. Diyanet geprüft?
2. Nūr al-Īḍāḥ geprüft?
3. Koran direkt relevant?
4. Hadith direkt relevant?
5. tatsächlich verwendete Quelle
6. nicht verwendete Quelle und Grund
7. genaue Seite
8. offene fachliche Frage
9. Freigabestatus

## Hauptquelle 1

- **Werk:** İslam İlmihali
- **Herausgeber:** Diyanet İşleri Başkanlığı
- **Autoren:** Lütfi Şentürk, Seyfettin Yazıcı
- **Ausgabe:** 34. Auflage, Ankara 2019
- **Relevante Seiten:**
  - Wudu: S. 96–114
  - Tayammum: S. 115–119
  - Ghusl: S. 119–123
  - Hayd: ab S. 124
  - Nifās: ab S. 127
  - Istihāda: ab S. 128
  - entschuldigte Personen: ab S. 131
- **Wortlaut übernommen:** nein

Diyanet trennt auf S. 120 ausdrücklich Manī, Mezi und Vedi und nennt deren unterschiedliche Auswirkungen auf Ghusl und Wudu.

## Hauptquelle 2

- **Werk:** Nūr al-Īḍāḥ
- **Autor:** Hasan ibn Ammar asch-Schurunbulālī
- **Verwendete Ausgabe:** arabischer Grundtext mit englischer Übersetzung und Erläuterungen von Wesam Charkawi
- **Relevante Bereiche:** Wudu, Tayammum, Ghusl, Hayd, Nifās, Istihāda
- **Wortlaut übernommen:** nein
- **Hinweis:** Exakte Seiten für Manī, Madhy, Wady und einzelne Ghusl-Grenzfälle noch gesondert ergänzen.

---

# Fragen an die hanafitische Fachprüfung

1. Sind die einfachen Erklärungen von Manī, Madhy und Wady korrekt und ausreichend abgegrenzt?
2. Ist „Samenflüssigkeit“ der geeignete deutsche Hauptbegriff für Manī bei Männern und Frauen?
3. Darf „Lusttropfen“ als alltagssprachliche Erklärung für Madhy verwendet werden?
4. Welche sichtbare Beschreibung von Wady ist fachlich korrekt, ohne medizinische Diagnosewirkung?
5. Welche Aussagen zu Reinigung und Wudu bei Madhy und Wady müssen ergänzt werden?
6. Wie soll ein feuchter Traum ohne festgestellte Flüssigkeit erklärt werden?
7. Wie soll Feuchtigkeit ohne Erinnerung an einen Traum erklärt werden?
8. Welche Sonderfälle zu Restflüssigkeit nach Ghusl gehören in das Glossar und welche nur in das Ghusl-Modul?
9. Sind die einfachen Definitionen von Hayd, Nifās und Istihāda korrekt?
10. Welche Zeitgrenzen dürfen in einer Anfänger-App sichtbar erklärt werden?
11. Welche Zeitgrenzen sollten nur in einem fachlich geprüften Detailmodul erscheinen?
12. Wie vermeiden wir, dass Nutzer Blutungen anhand des Glossars selbst verbindlich diagnostizieren?
13. Ist die Definition von Janāba für Anfänger verständlich?
14. Ist „große rituelle Unreinheit“ der geeignete deutsche Hauptbegriff?
15. Welche Begriffe benötigen zwingend einen Gelehrtenhinweis?
16. Welche Begriffe benötigen zusätzlich einen medizinischen Hinweis?
17. Welche Einträge können zur Veröffentlichung freigegeben werden?
18. Welche Einträge müssen vor Veröffentlichung überarbeitet werden?

**Für jede Prüfung später dokumentieren:**

- Name
- Qualifikation
- Datum
- Antwort
- Korrekturen
- freigegebener Wortlaut
- Einschränkungen

---

# Offene Punkte

- exakte Nūr-al-Īḍāḥ-Seiten für Manī ergänzen
- exakte Nūr-al-Īḍāḥ-Seiten für Madhy ergänzen
- exakte Nūr-al-Īḍāḥ-Seiten für Wady ergänzen
- genaue arabische Schreibweisen und Vokalisationen prüfen
- Transliteration projektweit vereinheitlichen
- Begriffe mit Wudu- und Ghusl-Modulen verlinken
- Glossar fachlich prüfen lassen
- entscheiden, welche Begriffe global und welche nur im religiösen Bereich sichtbar sind
- Flutter-Komponente für anklickbare Begriffe später separat planen
- noch keine automatische Klassifizierung von Flüssigkeiten oder Blutungen vorsehen

---

# Prüfstatus

- **Diyanet geprüft:** ja, zentrale Begriffe und Seiten dokumentiert
- **Nūr al-Īḍāḥ geprüft:** teilweise, genaue Seiten für einzelne Flüssigkeiten offen
- **Koran geprüft:** nicht als direkte Definitionsquelle aller Glossarbegriffe verwendet
- **Hadith geprüft:** noch nicht vollständig für einzelne Begriffe
- **App-Texte eigenständig formuliert:** ja
- **Diagnosefunktion vorgesehen:** nein
- **Individuelle Fatwa vorgesehen:** nein
- **Gelehrtenhinweise vorgesehen:** ja
- **Medizinische Hinweise vorgesehen:** ja
- **Fachlich endgeprüft:** nein
- **Zur Veröffentlichung freigegeben:** nein
- **Status:** Glossargrundlage erstellt – Quellenvervollständigung und fachliche Prüfung offen

---

*Siehe auch: `docs/religious_content_review_process.md`, `docs/wudu_steps/`, `docs/wudu_basics/`*
