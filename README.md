# ✅ Flutter Web Task Manager with Back4App (Parse REST API)

A clean, responsive **Flutter Web app** for managing personal tasks (CRUD), using the **Back4App REST API** for user authentication and task storage. Deployed on **Back4App Containers** with static web hosting.

---

## 🚀 Features

- 🔐 User Authentication (Sign up & Login)
- 📋 Create, Read, Update, Delete tasks
- 🧑‍💼 Tasks are user-specific via Parse Pointer
- 🧠 REST API calls using `http` (SDK-free, web-friendly)
- 🌐 Fully deployable on [Back4App Containers](https://containers.back4app.com)
- 📱 Responsive UI for Web

---

## 🧰 Tech Stack

| Layer      | Technology                        |
|------------|-----------------------------------|
| Frontend   | Flutter Web                       |
| Backend    | Back4App (Parse Server + REST API)|
| Hosting    | Back4App Containers (Nginx Static)|
| Auth       | Parse REST `/login`, `/users`     |
| DB         | Back4App Class `Task`             |

---

## 📦 Project Structure

lib/
├── main.dart
├── auth_page.dart
└── dashboard_page.dart

