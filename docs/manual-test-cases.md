# Manual Test Cases

## 1. Authentication

| Test Case ID | Title | Pre-conditions | Steps | Expected Result | Priority |
|--------------|-------|----------------|-------|-----------------|----------|
| AUTH-001 | Admin Login | App launched | 1. Navigate to Login<br>2. Enter valid Admin Email/Pass<br>3. Tap Login | Redirect to Admin Dashboard | High |
| AUTH-002 | Student Login | App launched | 1. Navigate to Login<br>2. Enter valid Student Email/Pass<br>3. Tap Login | Redirect to Student Dashboard/Quiz List | High |
| AUTH-003 | Invalid Login | App launched | 1. Enter invalid email or password<br>2. Tap Login | Show error message "User not found" or "Wrong password" | Medium |
| AUTH-004 | Registration | App launched | 1. Tap "Create Account"<br>2. Enter Name, Email, Password<br>3. Tap Register | Account created, logged in as Student | High |

## 2. Admin - Quiz Management

| Test Case ID | Title | Pre-conditions | Steps | Expected Result | Priority |
|--------------|-------|----------------|-------|-----------------|----------|
| ADM-001 | Create Quiz Manual | Logged in as Admin | 1. Tap "Create Quiz"<br>2. Enter Title, Desc, Time<br>3. Add 2 Questions manually<br>4. Save | Quiz appears in list, success message shown | High |
| ADM-002 | Upload CSV Valid | Logged in as Admin | 1. Tap "Create Quiz" -> "CSV Import"<br>2. Select `valid_quiz.csv`<br>3. Tap Import | Preview shows questions correctly. Quiz saved successfully. | High |
| ADM-003 | Upload CSV Invalid | Logged in as Admin | 1. Select `invalid_quiz.csv`<br>2. Tap Import | Error message lists validation failures (e.g., missing columns) | Medium |
| ADM-004 | Delete Quiz | Admin Dashboard | 1. Swipe left on a quiz<br>2. Tap Delete<br>3. Confirm | Quiz removed from list and Firestore | Medium |

## 3. Student - Quiz Attempt

| Test Case ID | Title | Pre-conditions | Steps | Expected Result | Priority |
|--------------|-------|----------------|-------|-----------------|----------|
| STU-001 | Start Quiz | Logged in as Student | 1. Tap on a Quiz Card | Quiz instructions/start screen opens | High |
| STU-002 | Attempt Quiz | Quiz Started | 1. Answer Q1<br>2. Tap Next<br>3. Answer Q2 | Progress bar updates, answers selected | High |
| STU-003 | Timer Expiry | Quiz Started | 1. Wait for timer to hit 00:00 | Quiz auto-submits, Result screen shown | High |
| STU-004 | Manual Submit | Quiz Started | 1. Answer all questions<br>2. Tap Submit | Result screen shows Score and Correct Answers | High |
| STU-005 | Resume Attempt | Quiz Started | 1. Close App<br>2. Re-open & Login<br>3. Tap same Quiz | **Expected**: Resume from last Q.<br>**Actual (Bug)**: Restarts from Q1. | High |

## 4. Edge Cases

| Test Case ID | Title | Pre-conditions | Steps | Expected Result | Priority |
|--------------|-------|----------------|-------|-----------------|----------|
| EDGE-001 | Network Cutoff | Quiz Started | 1. Turn off WiFi/Data<br>2. Tap Submit | Show "No Connection" error, retry option available | Medium |
| EDGE-002 | Empty CSV | Admin CSV Import | 1. Upload empty CSV file | Error: "File is empty" | Low |
| EDGE-003 | Large Text | Quiz Creation | 1. Enter 1000 char question text | Text wraps correctly, no UI overflow | Low |
