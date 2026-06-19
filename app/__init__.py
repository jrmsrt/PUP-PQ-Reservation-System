from flask import Flask, session, request, g, render_template
import os
from datetime import datetime
from flask_wtf.csrf import CSRFProtect

def create_app():
    # Load .env file manually if it exists to populate os.environ
    dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
    if os.path.exists(dotenv_path):
        with open(dotenv_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, val = line.split('=', 1)
                    os.environ[key.strip()] = val.strip()

    app = Flask(__name__, template_folder='templates', static_folder='static')
    secret_key = os.environ.get('FLASK_SECRET_KEY')
    if not secret_key:
        raise RuntimeError("FLASK_SECRET_KEY must be set before starting the app.")
    app.secret_key = secret_key
    app.config['SESSION_COOKIE_HTTPONLY'] = True
    app.config['SESSION_COOKIE_SAMESITE'] = os.environ.get('SESSION_COOKIE_SAMESITE', 'Lax')
    app.config['SESSION_COOKIE_SECURE'] = os.environ.get('SESSION_COOKIE_SECURE', 'false').lower() == 'true'
    CSRFProtect(app)


    # Context processors to inject global variables
    @app.context_processor
    def inject_globals():
        from app.server import get_current_user, get_mock_form
        return {
            'current_user': get_current_user(),
            'form': get_mock_form(),
            'datetime': datetime
        }

    # Custom jinja filters
    @app.template_filter('replace')
    def jinja_replace(s, old, new):
        return s.replace(old, new) if s else s

    # Register blueprints
    from app.server import auth_bp, student_bp, admin_bp, main_bp, ai_bp
    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(student_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(ai_bp)

    # Error Handlers
    @app.errorhandler(403)
    def forbidden(e):
        return render_template('shared/403.html'), 403

    @app.errorhandler(404)
    def page_not_found(e):
        return render_template('shared/404.html'), 404

    @app.errorhandler(500)
    def internal_server_error(e):
        return render_template('shared/500.html'), 500

    return app
