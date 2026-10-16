#  Real-time Public Bus & Train Tracking and Digital Ticketing App (transport_app)

A Flutter based mobile application project.

## Key Features

* User Authentication: Secure login and registration using Firebase Auth.
* Bus Route Selection: Browse available bus routes, fares, and schedules.
* Instant Ticket Booking: Book tickets easily with automatic fare calculation.
* Dynamic QR Code Generation: Real-time QR code generation for booked tickets using `qr_flutter`.
* My Tickets & Active Ticket View: View currently valid active tickets with live dynamic QR codes.
* Ticket History: View past/used tickets along with purchase date, time, and fare details.
* Cloud Firestore Integration: Real-time data synchronization for user ticket management.

-------------

##  Tech Stack & Dependencies

* Framework: [Flutter](https://flutter.dev/) (Dart)
* Backend / Database: [Firebase Firestore](https://firebase.google.com/)
* Authentication: Firebase Auth
* Packages Used:
  * `cloud_firestore` - Database storage for tickets
  * `firebase_auth` - User session management
  * `qr_flutter` - Dynamic QR code generation


## 📖 How to Use the App

### 1. User Authentication (Logging In / Creating an Account)
* Upon opening the app, enter your email and password.
* If you are a new user, please register to create a new account.

### 2. Find Your Transport
1. Navigate to the **Find Your Transport** section from the home screen.
2. Search the bus route for your journey.
3. Select your bus.
4. Click **BUY TICKETS**.

### 3. Buy Tickets
1. Verify that the passenger name and all relevant details are correct.
2. Choose your preferred payment method.
3. **Click Confirm & Pay**

### 4. Accessing Your Active Ticket and QR Code
* Once a ticket is booked, you will be directed to the **My Digital Tickets** screen.
* At the top, your most recently purchased ticket will generated **QR Code**.
* Present this QR code to the bus conductor or inspector.

### 4. Viewing Ticket History (Checking Past Tickets)
* Click the **History Tickets** button located at the bottom of the **My Digital Tickets** screen.
* You can view details—such as the route, bus number, and fare—along with the date and time of purchase for all previously used (scanned) tickets via a pop-up dialog.





























A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
