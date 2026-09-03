from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo
from typing import Optional

import os
import time

INDIA_TZ = ZoneInfo("Asia/Kolkata")

import bcrypt
import jwt
import redis
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, create_engine, func
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg2://hrms:hrms@localhost:5432/hrms",
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    password: Mapped[str] = mapped_column(String(200), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False)

    employee: Mapped[Optional["Employee"]] = relationship(back_populates="user")


class Department(Base):
    __tablename__ = "departments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)

    employees: Mapped[list["Employee"]] = relationship(back_populates="department")


class Employee(Base):
    __tablename__ = "employees"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    employee_code: Mapped[str] = mapped_column(String(30), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    phone: Mapped[str] = mapped_column(String(20), default="")
    designation: Mapped[str] = mapped_column(String(80), default="")
    joining_date: Mapped[date] = mapped_column(Date, default=date.today)
    active: Mapped[bool] = mapped_column(Boolean, default=True)

    department_id: Mapped[int] = mapped_column(ForeignKey("departments.id"))
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), unique=True)

    department: Mapped["Department"] = relationship(back_populates="employees")
    user: Mapped[Optional["User"]] = relationship(back_populates="employee")
    attendance: Mapped[list["Attendance"]] = relationship(back_populates="employee")
    leaves: Mapped[list["Leave"]] = relationship(back_populates="employee")


class Attendance(Base):
    __tablename__ = "attendance"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    employee_id: Mapped[int] = mapped_column(ForeignKey("employees.id"))
    day: Mapped[date] = mapped_column(Date, default=date.today)
    check_in: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    check_out: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="Present")

    employee: Mapped["Employee"] = relationship(back_populates="attendance")


class Leave(Base):
    __tablename__ = "leaves"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    employee_id: Mapped[int] = mapped_column(ForeignKey("employees.id"))
    leave_type: Mapped[str] = mapped_column(String(30))
    from_date: Mapped[date] = mapped_column(Date)
    to_date: Mapped[date] = mapped_column(Date)
    reason: Mapped[str] = mapped_column(String(300))
    status: Mapped[str] = mapped_column(String(20), default="Pending")

    employee: Mapped["Employee"] = relationship(back_populates="leaves")


app = FastAPI(title="Simple HRMS API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_KEY = "change-this-secret-before-production"
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=6379,
    decode_responses=True,
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def check_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())


def make_token(user: User) -> str:
    data = {
        "user_id": user.id,
        "role": user.role,
        "exp": datetime.utcnow() + timedelta(hours=8),
    }
    return jwt.encode(data, SECRET_KEY, algorithm="HS256")


def current_user(token: str, db: Session) -> User:
    try:
        data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user = db.get(User, data["user_id"])
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class EmployeeRequest(BaseModel):
    employee_code: str
    name: str
    email: EmailStr
    phone: str = ""
    designation: str = ""
    joining_date: date
    department_id: int
    password: Optional[str] = None


class LeaveRequest(BaseModel):
    employee_id: int
    leave_type: str
    from_date: date
    to_date: date
    reason: str


@app.get("/")
def home():
    return {"message": "HRMS API is running"}


@app.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()

    if not user or not check_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if user.employee and not user.employee.active:
        raise HTTPException(status_code=403, detail="Employee account is inactive")

    employee_id = user.employee.id if user.employee else None

    return {
        "token": make_token(user),
        "role": user.role,
        "employee_id": employee_id,
        "email": user.email,
    }


def get_logged_in_user(
    authorization: Optional[str] = None,
    db: Session = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Login required")

    token = authorization.replace("Bearer ", "")
    return current_user(token, db)


# FastAPI does not automatically map the Authorization header to this simple
# parameter, so the actual routes use Header below.
from fastapi import Header


def logged_user(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Login required")
    return current_user(authorization.replace("Bearer ", ""), db)


@app.get("/employees")
def get_employees(
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    employees = db.query(Employee).all()

    return [
        {
            "id": e.id,
            "employee_code": e.employee_code,
            "name": e.name,
            "email": e.email,
            "phone": e.phone,
            "designation": e.designation,
            "department": e.department.name,
            "department_id": e.department_id,
            "joining_date": str(e.joining_date),
            "active": e.active,
            "has_login": e.user_id is not None,
        }
        for e in employees
    ]


@app.post("/employees")
def add_employee(
    data: EmployeeRequest,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    department = db.get(Department, data.department_id)
    if not department:
        raise HTTPException(status_code=404, detail="Department not found")

    if db.query(Employee).filter(Employee.employee_code == data.employee_code).first():
        raise HTTPException(status_code=400, detail="Employee code already exists")

    if db.query(Employee).filter(Employee.email == data.email).first():
        raise HTTPException(status_code=400, detail="Employee email already exists")

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Login email already exists")

    employee_user = None

    if data.password:
        employee_user = User(
            email=data.email,
            password=hash_password(data.password),
            role="EMPLOYEE",
        )
        db.add(employee_user)
        db.flush()

    employee = Employee(
        employee_code=data.employee_code,
        name=data.name,
        email=data.email,
        phone=data.phone,
        designation=data.designation,
        joining_date=data.joining_date,
        department_id=data.department_id,
        user_id=employee_user.id if employee_user else None,
    )

    db.add(employee)
    db.commit()
    db.refresh(employee)

    return {
        "message": "Employee added",
        "id": employee.id,
        "login_created": employee_user is not None,
    }


@app.put("/employees/{employee_id}")
def update_employee(
    employee_id: int,
    data: EmployeeRequest,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    employee = db.get(Employee, employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    other_employee = (
        db.query(Employee)
        .filter(Employee.email == data.email, Employee.id != employee_id)
        .first()
    )
    if other_employee:
        raise HTTPException(status_code=400, detail="Employee email already exists")

    other_user = (
        db.query(User)
        .filter(User.email == data.email, User.id != employee.user_id)
        .first()
    )
    if other_user:
        raise HTTPException(status_code=400, detail="Login email already exists")

    employee.employee_code = data.employee_code
    employee.name = data.name
    employee.email = data.email
    employee.phone = data.phone
    employee.designation = data.designation
    employee.joining_date = data.joining_date
    employee.department_id = data.department_id

    if employee.user:
        employee.user.email = data.email
        if data.password:
            employee.user.password = hash_password(data.password)
    elif data.password:
        employee_user = User(
            email=data.email,
            password=hash_password(data.password),
            role="EMPLOYEE",
        )
        db.add(employee_user)
        db.flush()
        employee.user_id = employee_user.id

    db.commit()

    return {"message": "Employee updated"}


@app.post("/employees/{employee_id}/create-login")
def create_employee_login(
    employee_id: int,
    password: str,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    if not password.strip():
        raise HTTPException(status_code=400, detail="Password is required")

    employee = db.get(Employee, employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    if employee.user_id:
        raise HTTPException(status_code=400, detail="Login already exists")

    existing_user = db.query(User).filter(User.email == employee.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email is already used by another login")

    employee_user = User(
        email=employee.email,
        password=hash_password(password),
        role="EMPLOYEE",
    )

    db.add(employee_user)
    db.flush()
    employee.user_id = employee_user.id
    db.commit()

    return {"message": "Employee login created"}


@app.delete("/employees/{employee_id}")
def delete_employee(
    employee_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    employee = db.get(Employee, employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    employee.active = False
    db.commit()

    return {"message": "Employee deactivated"}


@app.put("/employees/{employee_id}/activate")
def activate_employee(
    employee_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    employee = db.get(Employee, employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    employee.active = True
    db.commit()

    return {"message": "Employee activated"}


@app.get("/departments")
def get_departments(
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    return db.query(Department).all()


@app.post("/attendance/check-in")
def check_in(
    employee_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "EMPLOYEE":
        raise HTTPException(status_code=403, detail="Only employees can check in")

    employee = user.employee
    if not employee or employee.id != employee_id:
        raise HTTPException(status_code=403, detail="Not your account")

    today = datetime.now(INDIA_TZ).date()
    record = (
        db.query(Attendance)
        .filter(
            Attendance.employee_id == employee_id,
            Attendance.day == today,
        )
        .first()
    )

    if record:
        raise HTTPException(status_code=400, detail="Already checked in")

    record = Attendance(
        employee_id=employee_id,
        day=today,
        check_in=datetime.now(INDIA_TZ).replace(tzinfo=None),
        status="Present",
    )
    db.add(record)
    db.commit()

    return {"message": "Checked in", "time": str(record.check_in)}


@app.post("/attendance/check-out")
def check_out(
    employee_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "EMPLOYEE":
        raise HTTPException(status_code=403, detail="Only employees can check out")

    employee = user.employee
    if not employee or employee.id != employee_id:
        raise HTTPException(status_code=403, detail="Not your account")

    record = (
        db.query(Attendance)
        .filter(
            Attendance.employee_id == employee_id,
            Attendance.day == datetime.now(INDIA_TZ).date(),
        )
        .first()
    )

    if not record:
        raise HTTPException(status_code=400, detail="Check in first")

    if record.check_out:
        raise HTTPException(status_code=400, detail="Already checked out")

    record.check_out = datetime.now(INDIA_TZ).replace(tzinfo=None)
    db.commit()

    return {"message": "Checked out", "time": str(record.check_out)}


@app.get("/attendance/{employee_id}")
def attendance_history(
    employee_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role == "EMPLOYEE" and (not user.employee or user.employee.id != employee_id):
        raise HTTPException(status_code=403, detail="Not your account")

    records = (
        db.query(Attendance)
        .filter(Attendance.employee_id == employee_id)
        .order_by(Attendance.day.desc())
        .all()
    )

    return [
        {
            "date": str(r.day),
            "check_in": str(r.check_in) if r.check_in else "",
            "check_out": str(r.check_out) if r.check_out else "",
            "status": r.status,
        }
        for r in records
    ]


@app.post("/leaves")
def apply_leave(
    data: LeaveRequest,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role == "EMPLOYEE":
        if not user.employee or user.employee.id != data.employee_id:
            raise HTTPException(status_code=403, detail="Not your account")

    if data.to_date < data.from_date:
        raise HTTPException(status_code=400, detail="Invalid dates")

    leave = Leave(
        employee_id=data.employee_id,
        leave_type=data.leave_type,
        from_date=data.from_date,
        to_date=data.to_date,
        reason=data.reason,
    )
    db.add(leave)
    db.commit()
    db.refresh(leave)

    return {"message": "Leave applied", "id": leave.id}


@app.get("/leaves")
def get_leaves(
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    query = db.query(Leave)

    if user.role == "EMPLOYEE":
        if not user.employee:
            return []
        query = query.filter(Leave.employee_id == user.employee.id)

    leaves = query.order_by(Leave.id.desc()).all()

    return [
        {
            "id": leave.id,
            "employee_id": leave.employee_id,
            "employee_name": leave.employee.name,
            "leave_type": leave.leave_type,
            "from_date": str(leave.from_date),
            "to_date": str(leave.to_date),
            "reason": leave.reason,
            "status": leave.status,
        }
        for leave in leaves
    ]


@app.put("/leaves/{leave_id}/approve")
def approve_leave(
    leave_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    leave = db.get(Leave, leave_id)
    if not leave:
        raise HTTPException(status_code=404, detail="Leave not found")

    leave.status = "Approved"
    db.commit()

    return {"message": "Leave approved"}


@app.put("/leaves/{leave_id}/reject")
def reject_leave(
    leave_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    if user.role != "HR":
        raise HTTPException(status_code=403, detail="HR access required")

    leave = db.get(Leave, leave_id)
    if not leave:
        raise HTTPException(status_code=404, detail="Leave not found")

    leave.status = "Rejected"
    db.commit()

    return {"message": "Leave rejected"}


@app.get("/dashboard")
def dashboard(
    db: Session = Depends(get_db),
    user: User = Depends(logged_user),
):
    cache_key = "hrms:dashboard"

    if user.role == "HR":
        cached = redis_client.get(cache_key)
        if cached:
            import json
            return json.loads(cached)

    total = db.query(func.count(Employee.id)).filter(Employee.active == True).scalar()
    today = datetime.now(INDIA_TZ).date()

    present = (
        db.query(func.count(Attendance.id))
        .filter(Attendance.day == today)
        .scalar()
    )

    pending = (
        db.query(func.count(Leave.id))
        .filter(Leave.status == "Pending")
        .scalar()
    )

    result = {
        "total_employees": total,
        "present_today": present,
        "pending_leaves": pending,
    }

    if user.role == "HR":
        import json
        redis_client.setex(cache_key, 60, json.dumps(result))

    return result


def seed_data():
    db = SessionLocal()

    if db.query(User).count() > 0:
        db.close()
        return

    it = Department(name="IT")
    hr = Department(name="HR")
    finance = Department(name="Finance")
    db.add_all([it, hr, finance])
    db.commit()

    admin = User(
        email="admin@hrms.com",
        password=hash_password("admin123"),
        role="HR",
    )

    employee_user = User(
        email="employee@hrms.com",
        password=hash_password("employee123"),
        role="EMPLOYEE",
    )

    db.add_all([admin, employee_user])
    db.commit()

    employee = Employee(
        employee_code="EMP001",
        name="Demo Employee",
        email="employee@hrms.com",
        phone="9876543210",
        designation="Software Engineer",
        joining_date=date.today(),
        department_id=it.id,
        user_id=employee_user.id,
    )

    db.add(employee)
    db.commit()
    db.close()


def start_database():
    for attempt in range(15):
        try:
            Base.metadata.create_all(bind=engine)
            seed_data()
            print("Database is ready")
            return
        except Exception as error:
            print(f"Waiting for PostgreSQL... attempt {attempt + 1}/15")
            time.sleep(2)

    raise RuntimeError("Could not connect to PostgreSQL")


@app.on_event("startup")
def startup():
    start_database()
