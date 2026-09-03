# HRMS - HR Management System

> A simple Human Resource Management System for employees, attendance, and leave requests.

[![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?logo=flutter&logoColor=white)](frontend/)
[![FastAPI](https://img.shields.io/badge/API-FastAPI-009688?logo=fastapi&logoColor=white)](backend/)
[![Docker](https://img.shields.io/badge/Run-Docker-2496ED?logo=docker&logoColor=white)](docker-compose.yml)

## Features

| HR | Employee |
| --- | --- |
| Dashboard statistics | Personal dashboard |
| Add and edit employees | Daily check-in and check-out |
| Activate or deactivate employees | Attendance history |
| Create employee login accounts | Apply for leave |
| Approve or reject leave requests | Track leave status |

## Architecture

| Layer | Technology | Responsibility |
| --- | --- | --- |
| **Frontend** | Flutter + Dart | Responsive HR and employee application |
| **Backend** | FastAPI + Python | REST API, authentication, and business logic |
| **Database** | PostgreSQL 16 | Users, employees, departments, attendance, and leaves |
| **Cache** | Redis 7 | HR dashboard result caching |
| **Runtime** | Docker Compose | Runs the backend and supporting services |


## Repository Structure

```text
HRMS_simple/
├── backend/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── frontend/
│   ├── lib/main.dart
│   ├── pubspec.yaml
│   └── test/
├── postman/HRMS.postman_collection.json
├── docker-compose.yml
└── README.md
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Git
- Chrome, an Android emulator, or a physical device for Flutter

## Docker Setup

From the project root, start the backend, PostgreSQL, and Redis:

```bash
docker compose up --build
```

The services will be available at:

| Service | Address |
| --- | --- |
| FastAPI | http://localhost:8000 |
| PostgreSQL | `localhost:5433` |
| Redis | `localhost:6379` |

Stop the services with `Ctrl+C`, or run:

```bash
docker compose down
```

To remove the local database and recreate the demo data:

```bash
docker compose down -v
docker compose up --build
```

## Flutter Setup

Open a second terminal:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Set the API URL at the top of `frontend/lib/main.dart` for your target:

| Target | API URL |
| --- | --- |
| Chrome or desktop | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Physical device | `http://<computer-ip>:8000` |

For a physical device, connect the device and computer to the same network and
replace `<computer-ip>` with the computer's local IP address.

## Demo Credentials

| Role | Email | Password |
| --- | --- | --- |
| HR | `admin@hrms.com` | `admin123` |
| Employee | `employee@hrms.com` | `employee123` |

## API Reference

After login, send the returned token with authenticated requests:

```http
Authorization: Bearer <token>
```

### Authentication

| Method | Endpoint | Access |
| --- | --- | --- |
| `POST` | `/login` | Public |

### Employees and Departments

| Method | Endpoint | Access |
| --- | --- | --- |
| `GET` | `/employees` | Authenticated |
| `POST` | `/employees` | HR |
| `PUT` | `/employees/{employee_id}` | HR |
| `POST` | `/employees/{employee_id}/create-login` | HR |
| `DELETE` | `/employees/{employee_id}` | HR; deactivates employee |
| `PUT` | `/employees/{employee_id}/activate` | HR |
| `GET` | `/departments` | Authenticated |

### Dashboard and Attendance

| Method | Endpoint | Access |
| --- | --- | --- |
| `GET` | `/dashboard` | Authenticated |
| `POST` | `/attendance/check-in?employee_id={id}` | Matching employee |
| `POST` | `/attendance/check-out?employee_id={id}` | Matching employee |
| `GET` | `/attendance/{employee_id}` | HR or matching employee |

### Leave Management

| Method | Endpoint | Access |
| --- | --- | --- |
| `POST` | `/leaves` | Authenticated |
| `GET` | `/leaves` | HR sees all; employees see their own |
| `PUT` | `/leaves/{leave_id}/approve` | HR |
| `PUT` | `/leaves/{leave_id}/reject` | HR |

For request bodies and response schemas, open Swagger UI at
http://localhost:8000/docs. The Postman collection is available at
`postman/HRMS.postman_collection.json`.

## Database and Seed Behavior

The backend creates these tables automatically when it starts:

- `users`
- `departments`
- `employees`
- `attendance`
- `leaves`

When the database has no users, it also creates three departments, one HR demo
user, one employee demo user, and the `EMP001` demo employee. Existing data is
preserved on later restarts.

PostgreSQL data is stored in the Docker volume `postgres_data`.

## Future Enhancements

- Add employee profile photos and document management
- Add payroll and salary management
- Add email or push notifications for leave updates
- Add role-based permissions for more HR actions





