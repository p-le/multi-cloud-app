FROM python:3.9-slim-buster

# Send stdout/stderr out, do not buffer.
ENV PYTHONUNBUFFERED 1
ENV APP_HOME /app

# Copy application dependency manifests to the container image.
# Copying this separately prevents re-running pip install on every code change.
COPY requirements.txt ./

# RUN apt-get update && \
#     apt-get install -y \
#         gcc \
#         default-libmysqlclient-dev
# RUN apt-get -y clean && \
#     rm -rf /var/lib/apt/lists/*


# Install production dependencies.
RUN set -ex; \
    pip install -r requirements.txt;

# Copy local code to the container image.

WORKDIR $APP_HOME
COPY . ./

# Run the web service on container startup. Here we use the gunicorn
# webserver, with one worker process and 8 threads.
# For environments with multiple CPU cores, increase the number of workers
# to be equal to the cores available.
CMD exec gunicorn --chdir src --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
