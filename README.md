AI Language Buddy - Aplicație Inteligentă pentru Învățarea Limbilor Străine
📝 Descriere Proiect

AI Language Buddy este o platformă inovatoare concepută pentru a facilita învățarea interactivă a limbilor străine prin conversații dinamice cu un agent bazat pe Inteligență Artificială. Sistemul oferă o experiență de învățare naturală, integrând corecția automată a erorilor gramaticale, sugestii de vocabular și adaptarea dificultății în funcție de nivelul utilizatorului.
+2

🏗️ Arhitectura Sistemului
Proiectul adoptă o arhitectură de tip Client-Server decuplată, organizată într-un sistem de tip Monorepo pentru o gestionare eficientă a codului:

📂 Structura Folderelor
/backend: Construit cu Java 24 și Spring Boot 4. Gestionează logica AI și interfața cu baza de date.
+3

/frontend: Dezvoltat în Flutter. Oferă o interfață mobilă intuitivă și responsivă pentru utilizatorul final.
+2

🛠️ Tehnologii Utilizate

Backend: Spring Boot, Spring AI, JPA/Hibernate.
+1


Frontend: Flutter (Dart).
+1


Baza de Date: PostgreSQL găzduită pe Supabase.
+1


AI Engine: Modelele Llama 3.1 via API-ul Groq, folosind protocolul OpenAI compatibil.
+1

💎 Principii de Design și Clean Architecture
Aplicația este construită respectând standardele moderne de inginerie software:

1. Clean Architecture (Backend)
   Sistemul este divizat în straturi clar definite pentru a asigura mentenanța și scalabilitatea:
   +1

Controller Layer (API): Gestionează endpoint-urile REST și comunicarea cu frontend-ul. Folosește @CrossOrigin pentru interconectivitate.

Service Layer (Business Logic): Aici rezidă „creierul” aplicației. Gestionează construcția prompt-urilor pentru AI și logica de corecție.
+1


Repository Layer (Data Access): Interfața cu PostgreSQL prin Spring Data JPA, asigurând persistența mesajelor și progresului.
+1


Domain/Model Layer: Definește entitățile sistemului (Utilizator, Mesaj, Corecție) conform diagramei logice IDEF1X.
+1

2. Design Patterns Utilizate
   Dependency Injection (DI): Folosit masiv prin Constructor Injection în Spring Boot pentru a asigura un cod testabil și slab cuplat.


Repository Pattern: Pentru abstractizarea accesului la date.


Strategy Pattern: (Inerente în Spring AI) permite schimbarea rapidă a modelelor LLM (ex: trecerea de la Llama 3 la Llama 3.3) doar prin configurare.

Singleton: Gestionat de contextul Spring pentru serviciile critice.

3. Reutilizarea Codului și SOLID
   Single Responsibility Principle (SRP): Fiecare clasă are un singur scop (ex: ChatService se ocupă doar de interacțiunea cu AI-ul).


Don't Repeat Yourself (DRY): Logica de calcul a progresului și corecția sunt centralizate în backend pentru a fi consumate de orice viitor client (Mobile, Web sau Desktop).
+1

⚙️ Configurare și Instalare
Backend (Spring Boot)
Navighează în folderul /backend.

Configurează src/main/resources/application.properties cu cheia ta API Groq și link-ul JDBC de la Supabase.

Rulează aplicația folosind Maven: ./mvnw spring-boot:run.

Frontend (Flutter)
Navighează în folderul /frontend.

Instalează dependințele: flutter pub get.

Configurează adresa IP a backend-ului în serviciul de comunicație.

Rulează pe simulator sau dispozitiv fizic: flutter run.

📊 Modelares și Analiză (Metodologie)
Conform documentației atașate (LDA), proiectul urmează un proces riguros de analiză:


IDEF0: Pentru definirea funcțiilor principale și a fluxurilor ICOM.
+1


DFD: Pentru vizualizarea transformărilor de date în timpul corecției lingvistice.


IDEF3: Pentru capturarea scenariilor secvențiale de chat în timp real.


Gantt & WBS: Proiectul este planificat pe etape (Management, UI/UX, Backend, Frontend, QA) pentru a respecta termenele de livrare.
+1

🛡️ Securitate și Conformitate

GDPR: Datele conversaționale și istoricul sunt stocate securizat în Supabase.


Protocol: Toate comunicațiile externe (Groq API) sunt realizate prin conexiuni securizate.