Der ADP Workforce Source Connector verbindet ADP Workforce über die Identity & Access Management (IAM) Lösung HelloID von Tools4ever mit Ihren Zielsystemen. Diese Verbindung vereinfacht die Verwaltung von Zugangsrechten und Autorisierungen innerhalb Ihrer Organisation, sorgt für Konsistenz und reduziert die Fehleranfälligkeit. In diesem Artikel erfahren Sie mehr über diese Integration, spezifische Möglichkeiten und Vorteile.

## Was ist ADP Workforce

ADP Workforce ist eine cloudbasierte Human Capital Management (HCM)-Lösung, die von ADP speziell für den niederländischen Markt entwickelt wurde. Die Lösung richtet sich hauptsächlich an private und öffentliche Organisationen mit mehr als tausend Mitarbeitern. ADP Workforce kombiniert Gehaltsabrechnung, HR, Talententwicklung und die Verwaltung von Mitarbeiterdaten in einem einzigen Registrierungssystem, das diese Prozesse automatisiert und rationalisiert.

## Warum ist eine ADP Workforce-Anbindung nützlich?

Die Verwaltung von Benutzerkonten und Autorisierungen ist eine zeitaufwändige und komplexe Aufgabe, insbesondere wenn Ihre Organisation viele Mitarbeiter beschäftigt. Alle Änderungen, die Sie in ADP Workforce vornehmen, müssen auch in allen von Ihnen genutzten Zielsystemen verarbeitet werden. Durch die Anbindung von ADP Workforce über HelloID an Ihre Zielsysteme entfällt dieser Prozess für Sie. HelloID erkennt automatisch Änderungen in ADP Workforce und führt basierend darauf die notwendigen Änderungen in Ihren Zielsystemen durch. So können Sie sicher sein, dass die Mitarbeiter immer optimal produktiv arbeiten können. Der ADP Workforce-Connector ermöglicht Verbindungen zu gängigen Zielsystemen wie:

* Entra ID
* Salto Space

Weitere Details zur Verbindung mit diesen Zielsystemen finden Sie weiter unten im Artikel.

## HelloID für ADP Workforce hilft Ihnen mit:

**Fehlerfreies Kontenmanagement:** Die Verwaltung von Benutzerkonten und Autorisierungen kann komplex sein, wobei die Komplexität mit dem Wachstum Ihrer Organisation weiter zunimmt. Fehler im Kontenmanagement können gleichzeitig viel Frustration, Behinderungen und Verzögerungen verursachen. Mitarbeiter können nicht auf die benötigten Anwendungen zugreifen, wodurch sie ihre Arbeit nicht erledigen können. Die Integration von ADP Workforce und HelloID sorgt für fehlerfreies Kontenmanagement und hebt Ihr Serviceniveau auf ein höheres Niveau.

**Schnelleres Erstellen von Konten:** Um optimal produktiv zu sein, ist der Zugang zu den richtigen Systemen und Daten erforderlich. Dazu gehört unter anderem die richtigen Konten und Autorisierungen. Bei der Einstellung neuer Mitarbeiter oder dem Wechsel von Mitarbeitern möchten Sie die benötigten Konten und richtigen Autorisierungen so schnell wie möglich erstellen. Mit HelloID automatisieren und beschleunigen Sie diesen Prozess, damit Ihre Mitarbeiter optimal arbeiten können.

**Stärkere Sicherheit:** Ein Cyberangriff kann großen Schaden verursachen. Sie möchten den Angreifern daher nicht mehr Raum bieten als unbedingt notwendig. Das erfordert unter anderem eine angemessene Verwaltung von Benutzerkonten und Autorisierungen. Sie möchten beispielsweise die Konten von ausscheidenden Mitarbeitern rechtzeitig sperren und überflüssige Autorisierungen so schnell wie möglich entziehen. So minimieren Sie die sogenannte Angriffsfläche und bieten böswilligen Akteuren so wenig Möglichkeiten wie möglich.

**Bidirektionale Synchronisation:** In einigen Fällen möchten Sie Informationen oder Änderungen von Ihren Zielsystemen an Ihr Quellsystem zurückmelden. Über unser GitHub-Repository steht hierfür ein spezieller Connector zur Verfügung, mit dem Sie die geschäftliche E-Mail-Adresse an ADP Workforce zurückmelden können.

## Wie HelloID mit ADP Workforce integriert
ADP Workforce und HelloID können mit einem Connector miteinander verbunden werden. Die HCM-Lösung fungiert dabei als Quellsystem für HelloID. Dank dieser Verbindung kann HelloID den gesamten Lebenszyklus von Konten in ADP Workforce automatisiert verwalten, sodass Sie nichts weiter zu tun haben. HelloID führt alle notwendigen Änderungen in Ihren Zielsystemen automatisch durch.

| Änderung in ADP Workforce | Prozedur in Zielsystemen |
| ----------------------------- | ------------------------ |
| **Neuer Mitarbeiter** | Basierend auf Informationen aus ADP Workforce erstellt HelloID ein Benutzerkonto in verbundenen Anwendungen mit den richtigen Gruppenmitgliedschaften. Je nach Funktion des neuen Mitarbeiters erstellt HelloID in verbundenen Systemen Benutzerkonten und weist die richtigen Rechte zu. |
| **Wechsel der Mitarbeiterfunktion** | HelloID ändert Benutzerkonten automatisch und weist gegebenenfalls andere Rechte in verbundenen Systemen zu. Das Autorisierungsmodell in HelloID ist dabei führend für die Zuweisung oder Entziehung von Berechtigungen. |
| **Namensänderung des Mitarbeiters** | Der Anzeigename und die E-Mail-Adresse werden (falls gewünscht) aktualisiert. |
| **Ausscheiden des Mitarbeiters** | HelloID deaktiviert Benutzerkonten in Zielsystemen und benachrichtigt die betroffenen Mitarbeiter in der Organisation. Nach einer bestimmten Zeit löscht die IAM-Lösung die Konten automatisch. |

HelloID nutzt die API von ADP Workforce, um einen Standardsatz an Daten in die HelloID Vault zu importieren. In diesem digitalen Tresor speichert die IAM-Lösung Informationen in einer einheitlichen Weise, indem Daten in die richtigen Felder gemappt werden. Dabei handelt es sich um Daten, die unter anderem Mitarbeiter, Vertragsdaten und Unternehmensinformationen betreffen.

## Maßgeschneiderter Datenaustausch
In ADP Workforce können Sie auf eine Vielzahl von kundenspezifischen Feldern zurückgreifen. Wenn Sie ADP Workforce mit HelloID koppeln, werden auch die Informationen aus diesen Feldern direkt mit der Verbindung übernommen. In HelloID können Sie diese kundenspezifischen Felder dann in die richtigen Felder in unserem sogenannten Personenschema mappen. Dies ermöglicht die Verwendung von Informationen aus benutzerdefinierten Feldern für die Kontenbereitstellung.

HelloID kann Informationen auch von Ihren Zielsystemen an ADP Workforce zurückmelden. Denken Sie dabei zum Beispiel an das Zurückmelden einer erstellten geschäftlichen E-Mail-Adresse an ADP Workforce. Das ist wichtig, denn so können Sie sicherstellen, dass die Daten in ADP Workforce immer aktuell sind.

## ADP Workforce über HelloID mit Zielsystemen verbinden
Sie können ADP Workforce über HelloID mit verschiedenen Zielsystemen verbinden. Diese Verbindung ermöglicht es, Informationen und Änderungen aus ADP Workforce automatisiert in Ihren Zielsystemen zu verarbeiten. Das ist angenehm, denn so brauchen Sie sich darum nicht zu kümmern und heben die Verwaltung von sowohl Benutzerkonten als auch Autorisierungen auf ein höheres Niveau. Einige häufige Integrationen sind:

**ADP Workforce - Microsoft Entra ID Verbindung:** Entra ID ist das cloudbasierte Gegenstück zu Active Directory. Mit HelloID können Sie diese Lösung nahtlos in ADP Workforce integrieren. Die Verbindung automatisiert verschiedene manuelle Aufgaben und verringert zudem die Wahrscheinlichkeit von menschlichen Fehlern. HelloID synchronisiert ADP Workforce und Entra ID automatisch, sodass Konten und Zugangsrechte immer auf dem neuesten Stand sind.

**ADP Workforce - Salto Space Verbindung:** Eine wichtige Voraussetzung für Produktivität ist der Zugang zu den richtigen Ressourcen. Dazu gehört auch der Zugang zu physischen Standorten wie einem Bürogebäude oder bestimmten Arbeits- oder Besprechungsräumen. Die Verbindung zwischen ADP Workforce und Salto Space gewährleistet, dass Sie sich darum nicht kümmern müssen und Mitarbeiter automatisch Zugang zu den Räumen erhalten, zu denen sie berechtigt sind. Dabei arbeiten Sie mit Zugangspools, die HelloID basierend auf Mitarbeiterinformationen einrichtet. HelloID blockiert auch automatisch den Zugang in Salto Space, wenn Mitarbeiter das Unternehmen verlassen.

Wir bieten für HelloID mehr als 200 Connectors an, mit denen Sie die IAM-Lösung an eine große Anzahl von Quell- und Zielsystemen anschließen können. Dank der breiten Integrationsmöglichkeiten erhalten Sie die Freiheit, ADP Workforce mit allen gängigen Zielsystemen zu verbinden.