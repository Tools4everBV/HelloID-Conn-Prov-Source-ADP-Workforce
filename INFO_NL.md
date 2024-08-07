De ADP Workforce Source Connector koppelt ADP Workforce via de identity & access management (IAM) oplossing HelloID van Tools4ever aan je doelsystemen. De koppeling vereenvoudigt het beheer van toegangsrechten en autorisaties binnen je organisatie, zorgt daarbij voor consistentie en dringt de foutgevoeligheid terug. In dit artikel lees je meer over deze integratie, specifieke mogelijkheden en voordelen. 

## Wat is ADP Workforce

ADP Workforce is een cloudgebaseerd Human Capital Management (HCM)-oplossing die door ADP specifiek is ontwikkeld voor de Nederlandse markt. De oplossing is met name gericht op particuliere en publieke organisaties met meer dan duizend medewerkers. ADP Workforce combineert payroll, HR, talentontwikkeling en het beheer van werknemersgegevens in één registratiesysteem, dat deze processen automatiseert en stroomlijnt. 

## Waarom is een ADP Workforce koppeling handig?

Het beheren van gebruikersaccounts en autorisaties is een tijdrovende en complexe taak, zeker indien je organisatie veel medewerkers telt. Alle mutaties die je uitvoert in ADP Workforce, moet je ook verwerken in alle doelsystemen waarvan je gebruik maakt. Door ADP Workforce via HelloID te koppelen aan je doelsystemen heb je naar dit proces geen omkijken. HelloID detecteert automatisch wijzigingen in ADP Workforce en voert op basis hiervan de benodigde mutaties uit in je doelsystemen. Zo weet je zeker dat medewerkers altijd optimaal productief kunnen zijn. De ADP Workforce connector maakt een koppeling met veelvoorkomende doelsystemen mogelijk, zoals:

*	Entra ID
*	Salto Space

Verdere details over de koppeling met deze doelsystemen zijn te vinden verderop in het artikel.

## HelloID voor ADP Workforce helpt je met

**Foutloos accountbeheer:** Het beheren van gebruikersaccounts en autorisaties kan complex zijn, waarbij naarmate je organisatie groeit de complexiteit steeds verder toeneemt. Fouten bij accountbeheer kunnen tegelijkertijd veel frustratie, hinder en vertraging opleveren. Zo kunnen werknemers niet bij de benodigde applicaties, waardoor zij niet aan de slag kunnen. De integratie van ADP Workforce en HelloID zorgt voor foutloos accountbeheer, waarmee je je serviceniveau naar een hoger niveau tilt.

**Accounts sneller aanmaken:** Optimaal productief zijn vereist toegang tot de juiste systemen en gegevens. Dit vraagt onder meer om de juiste accounts en autorisaties. Indien nieuwe medewerkers instromen of werknemers doorstromen wil je dan ook zo snel mogelijk de accounts die zij nodig hebben aanmaken en de juiste autorisaties toekennen. Met behulp van HelloID automatiseer en versnel je dit proces, waarmee je werknemers optimaal aan de slag helpt. 

**Sterkere beveiliging:** Een cyberaanval kan veel schade opleveren. Je wilt aanvallers dan ook niet meer ruimte geven dan strikt noodzakelijk. Dat vraagt onder meer om adequaat beheer van gebruikersaccounts en autorisaties. Je wilt bijvoorbeeld accounts van medewerkers die uitstromen tijdig blokkeren en overbodige autorisaties zo snel mogelijk intrekken. Zo minimaliseer je het zogeheten aanvalsoppervlak en biedt je kwaadwillenden zo min mogelijk opties.

**Bidirectionele synchronisatie:** In sommige gevallen wil je informatie of mutaties vanuit je doelsystemen terugkoppelen naar je bronsysteem. Via onze GitHub-repository is hiervoor een speciale connector beschikbaar, waarmee je het zakelijke e-mailadres kunt terugkoppelen naar ADP Workforce.

## Hoe HelloID integreert met ADP Workforce
ADP Workforce en HelloID kan je met behulp van een connector aan elkaar koppelen. De HCM-oplossing fungeert hierbij als bronsysteem voor HelloID. Dankzij deze koppeling kan HelloID de volledige levenscyclus van accounts in ADP Workforce geautomatiseerd beheren, zodat jij hiernaar geen omkijken hebt. Ook voert HelloID alle benodigde mutaties in je doelsystemen automatisch uit. 

| Wijziging in ADP Workforce| Procedure in doelsystemen |
| --------------------------- | ------------------------ | 
| **Nieuwe medewerker**	| Op basis van informatie uit ADP Workforce maakt HelloID een gebruikersaccount aan in gekoppelde applicaties met de juiste groepslidmaatschappen. Afhankelijk van de functie van de nieuwe medewerkers maakt HelloID daarnaast in gekoppelde systemen gebruikersaccounts aan en wijst de juiste rechten toe. |
| **Andere functie medewerker** |	HelloID muteert gebruikersaccounts automatisch en kent indien nodig andere rechten toe in gekoppelde systemen. Het autorisatiemodel in HelloID is hierbij leidend voor het toekennen of juist intrekken van autorisaties. |
| **Medewerker wijzigt naam** |	De weergavenaam en het e-mailadres worden (indien gewenst) aangepast |
| **Medewerker treedt uit dienst** |	HelloID deactiveert gebruikersaccounts in doelsystemen en informeert betrokken medewerkers in de organisatie. Na verloop van tijd verwijdert de IAM-oplossing automatisch de accounts.| 

HelloID zet de API van ADP Workforce in voor het importeren van een standaardset aan gegevens in de HelloID Vault. In deze digitale kluis slaat de IAM-oplossing informatie op een uniforme wijze op door data deze naar de juiste velden te mappen. Het gaat daarbij onder meer gegevens gerelateerd aan medewerkers, contractgegevens en bedrijfsinformatie. 

## Gegevensuitwisseling op maat
Je kunt in ADP Workforce gebruikmaken van allerlei maatwerkvelden. Indien je ADP Workforce met HelloID koppelt komt ook de informatie uit deze velden direct mee vanuit de koppeling. In HelloID kan je deze maatwerkvelden vervolgens mappen naar de juiste velden in ons zogeheten personschema. Dit maakt het mogelijk ook gegevens uit maatwerkvelden te gebruiken voor accountprovisioning. 

HelloID kan ook informatie uit je doelsystemen terugkoppelen naar ADP Workforce. Denk hierbij aan het terugkoppelen van een aangemaakt zakelijk e-mailadres naar ADP Workforce. Belangrijk, want zo weet je zeker dat de gegevens in ADP Workforce altijd up-to-date zijn.

## ADP Workforce via HelloID koppelen met doelsystemen
Je kunt ADP Workforce via HelloID aan diverse doelsystemen koppelen. Deze koppeling maakt het mogelijk informatie en mutaties uit ADP Workforce geautomatiseerd te verwerken in je doelsystemen. Prettig, want zo heb je hiernaar geen omkijken en til je het beheer van zowel gebruikersaccounts als autorisaties naar een hoger niveau. Enkele veelvoorkomende integraties zijn:

**ADP Workforce - Microsoft Entra ID koppeling:** Entra ID is de cloudgebaseerde tegenhanger van Active Directory. Je kunt deze oplossing met behulp van HelloID naadloos integreren met ADP Workforce. De koppeling automatiseert diverse handmatige taken en dringt daarnaast de kans op menselijke fouten terug. HelloID synchroniseert ADP Workforce en Entra ID automatisch, en zorgt zo dat accounts en toegangsrechten altijd up-to-date zijn. 

**ADP Workforce - Salto Space koppeling:** Een belangrijke voorwaarde voor productief zijn is de toegang tot de juiste middelen. Daaronder valt ook toegang tot fysieke locaties zoals een kantoorpand of specifieke werk- of vergaderruimte. De koppeling tussen ADP Workforce en Salto Space zorgt dat je hiernaar geen omkijken hebt en medewerkers automatisch toegang hebben tot de ruimten waartoe zij bevoegd zijn. Je werkt daarbij met toegangsgroepen, die HelloID inregelt op basis van medewerkersinformatie. Ook blokkeert HelloID automatisch de toegang in Salto Space indien medewerkers uitstromen.

We bieden voor HelloID meer dan 200 connectoren aan, waarmee je de IAM-oplossing kunt koppelen aan een groot aantal bron- en doelsystemen. Dankzij de brede integratiemogelijkheden krijg je de vrijheid om ADP Workforce aan alle populaire doelsystemen te koppelen. 
