# 📦 Product Management System

A full-stack product management application with Flutter frontend and Express.js backend using MS SQL Server database.

---

## 🖥️ Backend Setup

### Install Dependencies

```
npm init -y
npm install express mssql cors dotenv
npm install --save-dev nodemon
```

### Configure package.json

Add these properties:

```json
{
  "type": "module",
  "scripts": {
    "dev": "nodemon index.js"
  }
}
```

---

## 🗄️ Database Setup

### 1️⃣ Install MS SQL Server
- Server name: `YOUR_SYSTEM_NAME\SQLEXPRESS`

### 2️⃣ Create Database & Table

```sql
CREATE DATABASE PRODUCT_MANAGEMENT;

USE PRODUCT_MANAGEMENT;

CREATE TABLE PRODUCTS (
    PRODUCTID INT PRIMARY KEY IDENTITY(1,1),
    PRODUCTNAME NVARCHAR(100) NOT NULL,
    PRICE DECIMAL(10, 2) NOT NULL,
    STOCK INT NOT NULL
);

SELECT * FROM PRODUCTS;
```

### 3️⃣ Setup Authentication

- Right-click **Security** → Add new login
- Set username and password
- Enable **SQL Server authentication**

### 4️⃣ Enable Mixed Authentication Mode

- Server Properties → **Security** 
- Select "SQL Server and Windows Authentication mode"
- **Restart SQL Server**

### 5️⃣ Start Required Services

Ensure these are running:
- ✅ SQL Server (SQLEXPRESS)
- ✅ SQL Server Browser

> 💡 **Can't login?** Restart SQL Server and verify both services are running.

---

## 📱 Frontend Setup

### Install Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.1
  http: ^1.2.0
  path_provider: ^2.1.1
  syncfusion_flutter_pdf: ^23.1.36
  share_plus: ^7.2.1
  open_file: ^3.3.2
  permission_handler: ^11.0.1
  device_info_plus: ^10.1.0
```

### Configure Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
    
    <application>
        <!-- Your app configuration -->
    </application>
</manifest>
```

---

## 🚀 Running the Application

### Start Backend Server

```
cd backend
npm run dev
```

### Start Flutter App

```
cd frontend
flutter pub get
flutter run
```

---

