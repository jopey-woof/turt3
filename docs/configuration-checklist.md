# Turtle Enclosure System Configuration Checklist

Use this checklist to ensure you've configured all required values before deployment.

## 🔐 Required Configuration Values

### Email Configuration (for notifications)
- [ ] **Gmail Address**: `your-turtle-email@gmail.com` → `[YOUR_ACTUAL_EMAIL]`
- [ ] **Gmail App Password**: `your-app-password` → `[YOUR_APP_PASSWORD]`
- [ ] **Sender Email**: `your-turtle-email@gmail.com` → `[YOUR_ACTUAL_EMAIL]`
- [ ] **Recipient Email**: `your-personal-email@gmail.com` → `[YOUR_PERSONAL_EMAIL]`

**File**: `home-assistant/secrets.yaml`

### Home Assistant Token
- [ ] **Long-Lived Access Token**: `your-long-lived-access-token` → `[GENERATED_TOKEN]`

**File**: `home-assistant/secrets.yaml` (after Home Assistant is running)

### Camera Credentials
- [ ] **Camera Username**: `admin` → `[YOUR_CAMERA_USERNAME]` (if different)
- [ ] **Camera Password**: `your-camera-password` → `[YOUR_CAMERA_PASSWORD]`

**File**: `home-assistant/secrets.yaml`

### System Passwords
- [ ] **Turtle User Password**: `your_turtle_password` → `[STRONG_PASSWORD]`
- [ ] **InfluxDB Password**: `your_influxdb_password` → `[STRONG_PASSWORD]`
- [ ] **Grafana Password**: `your_grafana_password` → `[STRONG_PASSWORD]`

**Files**: 
- `scripts/deploy.sh` (turtle user)
- `docker/docker-compose.yml` (InfluxDB & Grafana)

## 📝 Configuration Steps

### Step 1: Email Setup
1. **Enable 2-Factor Authentication** on your Google Account
2. **Generate App Password**:
   - Go to Google Account → Security → 2-Step Verification
   - Click "App passwords"
   - Select "Mail" and generate password
3. **Update secrets.yaml** with your email and app password

### Step 2: System Passwords
1. **Generate strong passwords** (12+ characters, mixed case, numbers, symbols)
2. **Update deploy.sh** with turtle user password
3. **Update docker-compose.yml** with InfluxDB and Grafana passwords

### Step 3: Camera Setup
1. **Check camera manual** for default credentials
2. **Test camera access** with default credentials
3. **Update secrets.yaml** with actual camera credentials

### Step 4: Home Assistant Token (After Deployment)
1. **Start Home Assistant** (runs after deployment)
2. **Complete initial setup** (create admin account)
3. **Generate token**:
   - Profile → Long-Lived Access Tokens
   - Create new token named "Turtle Enclosure System"
4. **Update secrets.yaml** with the generated token
5. **Restart Home Assistant**: `docker-compose restart`

## ✅ Verification Checklist

After configuration, verify:

- [ ] **Email credentials** work (test with Home Assistant)
- [ ] **Camera is accessible** with configured credentials
- [ ] **System passwords** are strong and secure
- [ ] **Home Assistant token** is generated and working
- [ ] **All files** are saved with your actual values
- [ ] **No placeholder values** remain in any configuration files

## 🚨 Security Notes

- **Never commit** `secrets.yaml` with real passwords to Git
- **Use strong passwords** for all system accounts
- **Store passwords securely** (password manager recommended)
- **Keep backups** of your configuration files
- **Test all credentials** before final deployment

## 📞 Need Help?

If you're unsure about any configuration step:

1. **Check the main deployment guide**: `docs/deployment-guide.md`
2. **Review the troubleshooting section** for common issues
3. **Test credentials individually** before full deployment
4. **Use the test scripts** to verify hardware functionality

---

**🐢 Once all items are checked, you're ready to run the deployment script!** 