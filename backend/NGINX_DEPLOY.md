# Deployment Guide: Physical Server (Nginx + Local Database)

This guide walks you through deploying the EMS Backend to your physical server using **Nginx**.

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

### 3. Install Nginx
```bash
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 4. Install PostgreSQL
```bash
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 5. Create Database & User
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

## Nginx Configuration (Reverse Proxy)

We need Nginx to forward requests from the outside world (Port 80) to your Node app (Port 5000).

1. **Create Config File**:
   ```bash
   sudo nano /etc/nginx/sites-available/ems-backend
   ```

2. **Paste Configuration**:
   ```nginx
   server {
       listen 80;
       server_name 49.206.202.13;

       location / {
           proxy_pass http://localhost:5000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

3. **Enable Site**:
   Link the config to sites-enabled:
   ```bash
   sudo ln -s /etc/nginx/sites-available/ems-backend /etc/nginx/sites-enabled/
   ```

4. **Test & Restart Nginx**:
   ```bash
   sudo nginx -t
   sudo systemctl restart nginx
   ```

---

## How to Update

When you have pushed new code to GitHub, simply log in to your server and run:

```bash
cd /var/www/ems-backend/backend
./scripts/deploy.sh
```
