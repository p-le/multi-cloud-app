import os
import sys
from django.core.management import execute_from_command_line

if __name__ == "__main__":
    settings_module = os.getenv('SETTINGS_MODULE', 'app.dev_settings')
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", settings_module)
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)
