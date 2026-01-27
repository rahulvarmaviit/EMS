# Deployment Guide: Physical Server (Apache + Local Database)

This guide walks you through deploying the EMS Backend to your physical server .

## Prerequisites (Run these on your Server)

### 1. Install Node.js (v18+)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Install Git & PM2
```bash
sudo apt-get install -y git
sudo npm install -g pm2
```

### 3. Install PostgreSQL
```bash
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 4. Create Database & User
Log in to Postgres:
```bash
sudo -u postgres psql
```
Run these SQL commands (replace `password` with a secure password):
```sql
CREATE DATABASE ems_db;
CREATE USER ems_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE ems_db TO ems_user;
\q
```

---

## Application Setup

### 1. Clone the Repository
Navigate to your web directory (usually `/var/www`):
```bash
cd /var/www
sudo git clone https://github.com/rahulvarmaviit/EMS.git ems-backend
cd ems-backend/backend
```

### 2. Setup Environment Variables
Create the `.env` file:
```bash
cp .env.example .env
nano .env
```
Update `DATABASE_URL` with your postgres credentials:
```
DATABASE_URL="postgresql://ems_user:your_secure_password@localhost:5432/ems_db?schema=public"
```
Set other secrets (JWT_SECRET, etc.).

### 3. Initial Setup
Make the deploy script executable and run it:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### 4. Create Admin User
Initialize the system with your first admin account:
```bash
npx tsx scripts/create_admin.ts
```

---

## Apache Configuration (Reverse Proxy)

We need Apache to forward requests from the outside world (Port 80) to your Node app (Port 5000).

1. **Enable Proxy Modules**:
   ```bash
   sudo a2enmod proxy
   sudo a2enmod proxy_http
   ```

2. **Create Config File**:
   ```bash
   sudo nano /etc/apache2/sites-available/ems-backend.conf
   ```

3. **Paste Configuration**:
   Replace `your-server-ip` with your actual IP address.
   ```apache
   <VirtualHost *:80>
       ServerName 49.206.202.13
       
       # Proxy Settings
       ProxyPreserveHost On
       ProxyPass /api http://localhost:5000/api
       ProxyPassReverse /api http://localhost:5000/api
       
       # Optional: Serve static files or frontend if needed
       # DocumentRoot /var/www/ems-backend/frontend
   </VirtualHost>
   ```

4. **Enable Site & Restart Apache**:
   ```bash
   sudo a2ensite ems-backend
   sudo systemctl restart apache2
   ```

---

## How to Update

When you have pushed new code to GitHub, simply log in to your server and run:

```bash
cd /var/www/ems-backend/backend
./scripts/deploy.sh
```

This will automatically:
- Pull the latest code
- Install new dependencies
- Rebuild the app
- update the database
- Restart the server
