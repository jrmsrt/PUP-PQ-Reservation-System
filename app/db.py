import pymysql
import os
import secrets
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from markupsafe import Markup

# Load .env file manually if it exists to populate os.environ
dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
if os.path.exists(dotenv_path):
    with open(dotenv_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                os.environ[key.strip()] = val.strip()

class MySQLRow:
    def __init__(self, description, row_tuple):
        self._keys = [col[0] for col in description]
        self._values = row_tuple
        self._dict = dict(zip(self._keys, row_tuple))

    def __getitem__(self, key):
        if isinstance(key, int):
            return self._values[key]
        return self._dict[key]

    def keys(self):
        return self._keys
        
    def get(self, key, default=None):
        return self._dict.get(key, default)

class MySQLCursorWrapper:
    def __init__(self, cursor):
        self._cursor = cursor

    def execute(self, sql, params=None):
        sql_stripped = sql.strip().upper()
        if sql_stripped.startswith("PRAGMA"):
            return None
        sql_converted = sql.replace('?', '%s')
        return self._cursor.execute(sql_converted, params)

    def executemany(self, sql, params=None):
        sql_converted = sql.replace('?', '%s')
        return self._cursor.executemany(sql_converted, params)

    def fetchone(self):
        row = self._cursor.fetchone()
        if row is None:
            return None
        return MySQLRow(self._cursor.description, row)

    def fetchall(self):
        rows = self._cursor.fetchall()
        if not rows:
            return []
        desc = self._cursor.description
        return [MySQLRow(desc, r) for r in rows]

    @property
    def lastrowid(self):
        return self._cursor.lastrowid

    @property
    def rowcount(self):
        return self._cursor.rowcount

    def close(self):
        self._cursor.close()

class MySQLConnectionWrapper:
    def __init__(self, conn):
        self._conn = conn

    def cursor(self):
        return MySQLCursorWrapper(self._conn.cursor())

    def commit(self):
        self._conn.commit()

    def rollback(self):
        self._conn.rollback()

    def close(self):
        self._conn.close()

def get_db_connection():
    db_host = os.environ.get('DB_HOST', 'localhost')
    db_port = int(os.environ.get('DB_PORT', 3306))
    db_user = os.environ.get('DB_USER', 'root')
    db_password = os.environ.get('DB_PASSWORD')
    db_name = os.environ.get('DB_NAME', 'pup_reservation')
    create_database = os.environ.get('DB_CREATE_DATABASE', 'false').lower() == 'true'

    if not db_password:
        raise RuntimeError("DB_PASSWORD must be set before connecting to MySQL.")

    try:
        conn = pymysql.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            database=db_name,
            charset='utf8mb4'
        )
    except pymysql.err.OperationalError as exc:
        if not create_database:
            raise
        conn = pymysql.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            charset='utf8mb4'
        )
        cursor = conn.cursor()
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        cursor.close()
        conn.select_db(db_name)
    return MySQLConnectionWrapper(conn)

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Check for legacy schema mismatch (e.g. PK is not 'id' or table layout is old)
    need_drop = False
    
    # 1. Check authorized_users table
    cursor.execute("SHOW TABLES LIKE 'authorized_users'")
    if cursor.fetchone():
        cursor.execute("SHOW COLUMNS FROM authorized_users LIKE 'id'")
        if not cursor.fetchone():
            need_drop = True
            
    # 2. Check admin
    cursor.execute("SHOW TABLES LIKE 'admin'")
    if cursor.fetchone():
        cursor.execute("SHOW COLUMNS FROM admin LIKE 'id'")
        if not cursor.fetchone():
            need_drop = True

    # Check for table rename migration
    cursor.execute("SHOW TABLES LIKE 'reservations'")
    if cursor.fetchone():
        need_drop = True
        
    cursor.execute("SHOW TABLES LIKE 'reservation_requests'")
    if not cursor.fetchone():
        need_drop = True

    if need_drop:
        conn.close()
        raise RuntimeError(
            "Database schema is incompatible with this app version. "
            "Run an explicit migration or restore the expected schema; startup will not drop tables automatically."
        )

    # 1. admin table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS admin (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL
        ) ENGINE=InnoDB
    ''')
    
    # 2. authorized_users table (unified masterlist + users table)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS authorized_users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            student_number VARCHAR(50) UNIQUE NOT NULL,
            pup_email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            first_name VARCHAR(100) NOT NULL,
            middle_name VARCHAR(100) DEFAULT '',
            last_name VARCHAR(100) NOT NULL,
            email_verified BOOLEAN DEFAULT FALSE,
            password_changed BOOLEAN DEFAULT FALSE,
            account_status VARCHAR(20) DEFAULT 'ACTIVE',
            role VARCHAR(20) DEFAULT 'STUDENT',
            contact_number VARCHAR(20) DEFAULT '',
            program VARCHAR(20) DEFAULT 'BSIT',
            year_section VARCHAR(20) DEFAULT '1-1',
            failed_otp_attempts INT DEFAULT 0,
            lockout_until VARCHAR(50) DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB
    ''')
    
    # 3. otp_verifications table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS otp_verifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            otp_code VARCHAR(255) NOT NULL,
            expires_at VARCHAR(50) NOT NULL,
            is_used BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES authorized_users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB
    ''')
    cursor.execute("ALTER TABLE otp_verifications MODIFY otp_code VARCHAR(255) NOT NULL")
    
    # 4. facilities table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS facilities (
            id INT AUTO_INCREMENT PRIMARY KEY,
            code VARCHAR(50) UNIQUE NOT NULL,
            type VARCHAR(100) NOT NULL,
            status VARCHAR(50) DEFAULT 'Available'
        ) ENGINE=InnoDB
    ''')
    
    # 5. projectors table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS projectors (
            id INT AUTO_INCREMENT PRIMARY KEY,
            code VARCHAR(50) UNIQUE NOT NULL,
            model VARCHAR(100) NOT NULL,
            status VARCHAR(50) DEFAULT 'Available'
        ) ENGINE=InnoDB
    ''')
    
    # 6. reservation_requests table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS reservation_requests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            student_id INT NOT NULL,
            facility_type VARCHAR(100) NOT NULL,
            facility_id INT NULL,
            projector_id INT NULL,
            schedule_date VARCHAR(20) NOT NULL,
            start_time VARCHAR(20) NOT NULL,
            end_time VARCHAR(20) NOT NULL,
            course_code VARCHAR(50) NOT NULL,
            course_name VARCHAR(255) NOT NULL,
            professor VARCHAR(255) NOT NULL,
            status VARCHAR(50) DEFAULT 'PENDING APPROVAL',
            remarks TEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(student_id) REFERENCES authorized_users(id) ON DELETE CASCADE,
            FOREIGN KEY(facility_id) REFERENCES facilities(id) ON DELETE SET NULL,
            FOREIGN KEY(projector_id) REFERENCES projectors(id) ON DELETE SET NULL
        ) ENGINE=InnoDB
    ''')
    cursor.execute("SHOW COLUMNS FROM reservation_requests")
    reservation_columns = {row[0] for row in cursor.fetchall()}
    reservation_migrations = [
        ('checkout_time', "ALTER TABLE reservation_requests ADD COLUMN checkout_time VARCHAR(50) NULL"),
        ('return_time', "ALTER TABLE reservation_requests ADD COLUMN return_time VARCHAR(50) NULL"),
        ('released_by', "ALTER TABLE reservation_requests ADD COLUMN released_by VARCHAR(100) NULL"),
        ('received_by', "ALTER TABLE reservation_requests ADD COLUMN received_by VARCHAR(255) NULL"),
        ('returned_to', "ALTER TABLE reservation_requests ADD COLUMN returned_to VARCHAR(100) NULL"),
        ('equipment_condition', "ALTER TABLE reservation_requests ADD COLUMN equipment_condition TEXT NULL")
    ]
    for column_name, alter_sql in reservation_migrations:
        if column_name not in reservation_columns:
            cursor.execute(alter_sql)
    
    # 7. system_logs table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS system_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_username VARCHAR(50) NULL,
            student_id INT NULL,
            action VARCHAR(255) NOT NULL,
            details TEXT NOT NULL,
            ip_address VARCHAR(45) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(student_id) REFERENCES authorized_users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB
    ''')

    # 8. ai_settings table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS ai_settings (
            setting_key VARCHAR(100) PRIMARY KEY,
            setting_value VARCHAR(255) NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB
    ''')

    default_ai_settings = [
        ('buffer_minutes', '15'),
        ('auto_suggest', '1'),
        ('peak_warning', '1'),
        ('email_alerts', '1')
    ]
    cursor.executemany('''
        INSERT IGNORE INTO ai_settings (setting_key, setting_value)
        VALUES (?, ?)
    ''', default_ai_settings)

    # Seed Admin if not exists
    cursor.execute("SELECT COUNT(*) FROM admin")
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO admin (username, password_hash) VALUES (?, ?)", 
                       ('admin', generate_password_hash('RSadmin@1904')))
                       
    # Seed default facilities
    cursor.execute("SELECT COUNT(*) FROM facilities")
    if cursor.fetchone()[0] == 0:
        cursor.executemany("INSERT INTO facilities (code, type, status) VALUES (?, ?, ?)", [
            ('AVR-01', 'Audio-Visual Room (AVR)', 'Available'),
            ('COMP-LAB-01', 'Computer Laboratory', 'Available'),
            ('HM-LAB-01', 'Hospitality Management Laboratory', 'Available')
        ])
        
    # Seed default projectors
    cursor.execute("SELECT COUNT(*) FROM projectors")
    if cursor.fetchone()[0] == 0:
        cursor.executemany("INSERT INTO projectors (code, model, status) VALUES (?, ?, ?)", [
            ('PJ-001', 'Epson PowerLite X41', 'Available'),
            ('PJ-002', 'Epson PowerLite X42', 'Available'),
            ('PJ-003', 'Epson PowerLite X43', 'Available'),
            ('PJ-004', 'Epson PowerLite X44', 'Available'),
            ('PJ-005', 'Epson PowerLite X45', 'Available'),
            ('PJ-006', 'Epson PowerLite X46', 'Available'),
            ('PJ-007', 'Epson PowerLite X47', 'Available'),
            ('PJ-008', 'Epson PowerLite X48', 'Available'),
            ('PJ-009', 'Epson PowerLite X49', 'Available'),
            ('PJ-010', 'Epson PowerLite X50', 'Available')
        ])

    conn.commit()
    conn.close()

# Initialize DB on module import
init_db()

# Account Provisioning and whitelisting logic
def import_student_to_masterlist(student_number, first_name, last_name, email, middle_name='', program='BSIT', year_section='1-1'):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Check masterlist duplicate email or student number
        cursor.execute("SELECT COUNT(*) FROM authorized_users WHERE student_number = ? OR pup_email = ?", 
                       (student_number, email))
        if cursor.fetchone()[0] > 0:
            return False, "Duplicate student record in masterlist whitelist"
            
        # Insert into authorized_users
        default_pwd_hash = generate_password_hash('PUPrs@1904')
        cursor.execute('''
            INSERT INTO authorized_users (student_number, pup_email, password_hash, first_name, middle_name, last_name, program, year_section)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (student_number, email, default_pwd_hash, first_name, middle_name, last_name, program, year_section))
        
        conn.commit()
        return True, "Imported and provisioned student account successfully."
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        conn.close()

def get_student_by_email(email):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT id AS user_id, student_number, pup_email, password_hash,
               email_verified, password_changed, account_status, role,
               contact_number, program, year_section, failed_otp_attempts,
               lockout_until, created_at, first_name, last_name, middle_name
        FROM authorized_users
        WHERE pup_email = ?
    ''', (email,))
    row = cursor.fetchone()
    conn.close()
    return row

def get_student_masterlist_entry(email):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM authorized_users WHERE pup_email = ?", (email,))
    row = cursor.fetchone()
    conn.close()
    return row

def check_otp_rate_limit(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    # Calculate one hour ago formatted for string comparison
    one_hour_ago = (datetime.now() - timedelta(hours=1)).strftime('%Y-%m-%d %H:%M:%S')
    cursor.execute('''
        SELECT COUNT(*) FROM otp_verifications 
        WHERE user_id = ? AND created_at > ?
    ''', (user_id, one_hour_ago))
    count = cursor.fetchone()[0]
    conn.close()
    return count >= 5

def check_lockout_active(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT lockout_until FROM authorized_users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row and row['lockout_until']:
        lockout_time = datetime.strptime(row['lockout_until'], '%Y-%m-%d %H:%M:%S')
        if datetime.now() < lockout_time:
            return True, lockout_time
            
    return False, None

def generate_and_save_otp(user_id):
    otp = f"{secrets.randbelow(900000) + 100000}" # secure 6 digit OTP
    expires_at = (datetime.now() + timedelta(minutes=5)).strftime('%Y-%m-%d %H:%M:%S')
    otp_hash = generate_password_hash(otp)
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO otp_verifications (user_id, otp_code, expires_at, is_used)
        VALUES (?, ?, ?, 0)
    ''', (user_id, otp_hash, expires_at))
    conn.commit()
    conn.close()
    return otp

def verify_otp_code(user_id, otp_code):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Fetch active valid OTPs. New rows store password hashes; the plaintext
    # comparison keeps existing pre-migration OTPs valid until they expire.
    now_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    cursor.execute('''
        SELECT id AS otp_id, user_id, otp_code, expires_at, is_used, created_at FROM otp_verifications
        WHERE user_id = ? AND is_used = 0 AND expires_at > ?
        ORDER BY created_at DESC
    ''', (user_id, now_str))
    otp_record = None
    for candidate in cursor.fetchall():
        stored_code = candidate['otp_code']
        try:
            matches = check_password_hash(stored_code, otp_code)
        except Exception:
            matches = False
        if matches or stored_code == otp_code:
            otp_record = candidate
            break
    
    if otp_record:
        # Mark OTP as used
        cursor.execute("UPDATE otp_verifications SET is_used = 1 WHERE id = ?", (otp_record['otp_id'],))
        # Set email_verified = TRUE and reset attempts
        cursor.execute('''
            UPDATE authorized_users 
            SET email_verified = 1, failed_otp_attempts = 0, lockout_until = NULL 
            WHERE id = ?
        ''', (user_id,))
        conn.commit()
        conn.close()
        return True, "OTP verified successfully."
    else:
        # Increment failed attempts
        cursor.execute("SELECT failed_otp_attempts FROM authorized_users WHERE id = ?", (user_id,))
        row = cursor.fetchone()
        attempts = (row['failed_otp_attempts'] or 0) + 1
        
        lockout_until = None
        if attempts >= 5:
            lockout_until = (datetime.now() + timedelta(minutes=15)).strftime('%Y-%m-%d %H:%M:%S')
            cursor.execute('''
                UPDATE authorized_users 
                SET failed_otp_attempts = ?, lockout_until = ? 
                WHERE id = ?
            ''', (attempts, lockout_until, user_id))
            msg = "Too many failed attempts. Your account is temporarily locked for 15 minutes."
        else:
            cursor.execute('''
                UPDATE authorized_users SET failed_otp_attempts = ? WHERE id = ?
            ''', (attempts, user_id))
            msg = f"Invalid or expired OTP. {5 - attempts} attempts remaining before account lockout."
            
        conn.commit()
        conn.close()
        return False, msg
