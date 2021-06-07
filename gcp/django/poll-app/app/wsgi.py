import os

from django.core.wsgi import get_wsgi_application
env = os.getenv("ENV", "dev")
os.environ['DJANGO_SETTINGS_MODULE'] = f"app.{env}_settings"
application = get_wsgi_application()
