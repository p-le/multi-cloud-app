FROM python:3.9-slim

ENV PYTHONUNBUFFERED True
ENV APP_HOME /app

WORKDIR $APP_HOME

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN set -ex; \
  apt-get -y update; \
  apt-get -y install imagemagick; \
  rm -rf /var/lib/apt/lists/*

COPY . ./

CMD exec gunicorn --chdir src --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
