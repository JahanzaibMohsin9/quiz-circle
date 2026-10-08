# Firebase Setup Guide

## Easy Step-by-Step Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter a project name (for example `quiz-circle`)
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

### 2. Add Firebase to Flutter App

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Select platforms (Android, iOS, Web)
   - This will automatically download the required configuration files

### 3. Enable Firebase Services

#### Authentication Setup:
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password"
3. (Optional) Enable "Google" for Google Sign-In

#### Firestore Database Setup:
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in "Test mode" (for development)
4. Choose a location (closest to your users)

#### Firebase Storage Setup:
1. Go to Firebase Console → Storage
2. Click "Get started"
3. Start in "Test mode" (for development)

### 4. Create Firestore Collections

#### Users Collection
```
Collection: users
Document ID: Auto-generated (Firebase Auth UID)
Fields:
- id: string (Firebase Auth UID)
- name: string
- email: string
- role: string ("student" or "admin")
- allowedQuizzes: array of strings
- totalScore: number
- averagePercentage: number
- createdAt: timestamp
- lastLoginAt: timestamp
```

#### Quizzes Collection
```
Collection: quizzes
Document ID: Auto-generated
Fields:
- id: string
- title: string
- description: string
- category: string
- difficulty: string ("easy", "medium", "hard")
- timeLimit: number (in minutes)
- isActive: boolean
- createdBy: string (admin user ID)
- createdAt: timestamp
- updatedAt: timestamp
```

#### Quiz Questions Collection
```
Collection: quiz_questions
Document ID: Auto-generated
Fields:
- id: string
- quizId: string (references quizzes collection)
- questionText: string
- questionType: string ("multiple_choice", "true_false", "text")
- options: array of objects (for multiple choice)
  - text: string
  - isCorrect: boolean
- correctAnswer: string
- explanation: string (optional)
- imageUrl: string (optional)
- order: number
- points: number
```

#### Quiz Submissions Collection
```
Collection: submissions
Document ID: Auto-generated
Fields:
- id: string
- quizId: string (references quizzes collection)
- userId: string (references users collection)
- answers: array of objects
  - questionId: string
  - selectedAnswer: string
  - isCorrect: boolean
  - timeSpent: number (in seconds)
- score: number
- totalQuestions: number
- correctAnswers: number
- percentage: number
- timeSpent: number (total time in seconds)
- startedAt: timestamp
- submittedAt: timestamp
```

#### Leaderboard Collection
```
Collection: leaderboard
Document ID: quizId (references quizzes collection)
Fields:
- quizId: string
- entries: array of objects
  - userId: string
  - userName: string
  - score: number
  - percentage: number
  - timeSpent: number
  - submittedAt: timestamp
- lastUpdated: timestamp
```

### 5. Set Up Firestore Security Rules

The rules the app actually uses are in `firestore.rules` and `firestore.indexes.json` at the repo root, and `firebase deploy --only firestore:rules,firestore:indexes` applies them. The simplified version below shows the shape if you prefer to paste rules into the Firebase Console (Firestore → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && (
        request.auth.uid == userId || 
        request.auth.token.role == 'admin'
      );
      allow list: if request.auth != null;
    }
    
    // Quizzes collection
    match /quizzes/{quizId} {
      allow read: if request.auth != null && (
        request.auth.token.role == 'admin' ||
        (request.auth.token.role == 'student' && 
         resource.data.isActive == true)
      );
      allow write: if request.auth != null && request.auth.token.role == 'admin';
    }
    
    // Quiz questions collection
    match /quiz_questions/{questionId} {
      allow read: if request.auth != null && (
        request.auth.token.role == 'admin' ||
        (request.auth.token.role == 'student')
      );
      allow write: if request.auth != null && request.auth.token.role == 'admin';
    }
    
    // Submissions collection
    match /submissions/{submissionId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        request.auth.token.role == 'admin'
      );
      allow write: if request.auth != null && (
        request.auth.uid == request.resource.data.userId ||
        request.auth.token.role == 'admin'
      );
      allow list: if request.auth != null && request.auth.token.role == 'admin';
    }
    
    // Leaderboard collection
    match /leaderboard/{quizId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.role == 'admin';
    }
  }
}
```

### 6. Set Up Firebase Storage Security Rules

Go to Firebase Console → Storage → Rules and paste these rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Anyone can read images
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.role == 'admin';
    }
  }
}
```

### 7. Create Indexes for Better Performance

Go to Firebase Console → Firestore → Indexes and create these composite indexes:

1. **Submissions by User and Quiz**
   - Collection: submissions
   - Fields: userId (Ascending), quizId (Ascending)
   - Query scope: Collection

2. **Submissions by Quiz and Submitted Date**
   - Collection: submissions
   - Fields: quizId (Ascending), submittedAt (Descending)
   - Query scope: Collection

3. **Quizzes by Active Status**
   - Collection: quizzes
   - Fields: isActive (Ascending), createdAt (Descending)
   - Query scope: Collection

4. **Questions by Quiz and Order**
   - Collection: quiz_questions
   - Fields: quizId (Ascending), order (Ascending)
   - Query scope: Collection

### 8. Add Test Data (Optional)

Sign up in the app, set your user's `role` to `admin` in the `users` collection, then create a quiz in the admin dashboard or import one of the CSV files in `samples/`.

## Quick Setup Summary

1. ✅ Create Firebase project
2. ✅ Run `flutterfire configure`
3. ✅ Enable Authentication (Email/Password)
4. ✅ Create Firestore database
5. ✅ Set up Storage
6. ✅ Create collections (users, quizzes, quiz_questions, submissions, leaderboard)
7. ✅ Set security rules
8. ✅ Create indexes
9. ✅ Add test data (optional)

Your Firebase backend is now ready for Quiz Circle.