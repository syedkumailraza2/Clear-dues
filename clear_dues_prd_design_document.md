# Clear Dues
Expense Management & UPI-Based Dues Settlement App

---

## 1. Product Requirements Document (PRD)

### 1.1 Product Overview
**Product Name:** Clear Dues  
**Platform:** Mobile App (Android first, iOS later)  
**Tech Stack:** MEFN (MongoDB, Express, Flutter, Node.js)

Clear Dues helps users manage shared expenses, split bills with friends, track who owes whom, and settle dues instantly using UPI deep links.

---

### 1.2 Problem Statement
People often share expenses with friends, roommates, or colleagues but struggle to:
- Track who owes how much
- Avoid repeated reminders
- Settle payments quickly

Existing solutions are either too complex or not optimized for Indian UPI-first users.

---

### 1.3 Goals & Objectives
- Simplify expense splitting
- Minimize number of settlements
- Enable instant UPI payments
- Provide clear visibility of dues
- Keep the app fast, simple, and reliable

---

### 1.4 Target Users
1. College students
2. Flatmates / roommates
3. Friends on trips
4. Small teams / freelancers

---

### 1.5 User Personas
**Persona 1:** College Student  
Needs quick splitting & reminders

**Persona 2:** Working Professional  
Needs clean UI, reports, and fast settlement

---

### 1.6 Core Features (MVP)

#### Authentication
- Phone / Email login
- OTP-based verification

#### Group Management
- Create groups
- Invite members via link
- Assign group name & icon

#### Expense Management
- Add expense
- Split options:
  - Equal
  - Unequal
  - Percentage
- Attach notes

#### Dues Calculation
- Auto-calculate balances
- Show net amount per user
- Simplify transactions

#### UPI Payment Integration
- Pay via UPI deep link
- Pre-filled amount & note
- Mark dues as paid

#### Dashboard
- You owe
- You will receive
- Group-wise balances

---

### 1.7 Advanced Features (Post-MVP)
- Expense reminders
- Offline mode
- Receipt scanner
- Monthly reports (PDF/Excel)
- Recurring expenses
- Multi-currency support

---

### 1.8 Non-Functional Requirements
- Secure authentication (JWT)
- Fast sync (<2 sec)
- Data encryption
- High availability

---

### 1.9 Success Metrics
- Daily active users
- Expense creation rate
- Settlement completion rate
- User retention

---

## 2. Design Document (Technical & System Design)

### 2.1 System Architecture

**Client:** Flutter App  
**Backend:** Node.js + Express  
**Database:** MongoDB  
**Auth:** JWT  
**Payments:** UPI Deep Links

```
Flutter App
   ↓ REST API
Node.js / Express
   ↓
MongoDB
```

---

### 2.2 App Architecture (Flutter)
- MVVM / Clean Architecture
- Layers:
  - Presentation (UI)
  - Domain (Business logic)
  - Data (API, DB)

Local Storage:
- Hive / SharedPreferences

---

### 2.3 Backend Architecture

#### Modules
- Auth Module
- User Module
- Group Module
- Expense Module
- Settlement Module

---

### 2.4 Database Design (MongoDB)

#### User Schema
```json
{
  "_id": "ObjectId",
  "name": "String",
  "email": "String",
  "phone": "String",
  "upiId": "String",
  "createdAt": "Date"
}
```

#### Group Schema
```json
{
  "_id": "ObjectId",
  "name": "String",
  "members": ["userId"],
  "createdBy": "userId"
}
```

#### Expense Schema
```json
{
  "_id": "ObjectId",
  "groupId": "ObjectId",
  "paidBy": "userId",
  "amount": "Number",
  "splits": [
    { "userId": "userId", "amount": "Number" }
  ],
  "createdAt": "Date"
}
```

#### Settlement Schema
```json
{
  "from": "userId",
  "to": "userId",
  "amount": "Number",
  "status": "pending | paid"
}
```

---

### 2.5 API Design (Sample)

- POST /auth/login
- POST /groups
- POST /expenses
- GET /balances
- POST /settlements/pay

---

### 2.6 UPI Deep Link Flow

1. User taps "Pay Now"
2. App generates UPI URL
3. Opens installed UPI app
4. Payment completed
5. User confirms payment

---

### 2.7 Security Considerations
- JWT authentication
- Input validation
- Rate limiting
- Secure API keys

---

### 2.8 Scalability Considerations
- Indexing MongoDB
- Stateless APIs
- Cloud deployment (AWS/GCP)

---

### 2.9 Future Enhancements
- Web version
- Admin dashboard
- AI-based spend insights

---

## 3. Development Roadmap

### Phase 1 (Weeks 1–3)
- Auth
- Groups
- Expenses
- Dashboard

### Phase 2 (Weeks 4–6)
- Settlements
- UPI payments
- Notifications

### Phase 3 (Weeks 7–8)
- Reports
- Optimizations

---

**End of Document**

