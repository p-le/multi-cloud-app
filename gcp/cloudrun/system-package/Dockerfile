FROM python:3.9-slim

ENV PYTHONUNBUFFERED True
ENV APP_HOME /app

WORKDIR $APP_HOME

RUN apt-get update -y && \
    apt-get install -y \
        graphviz && \
    apt-get clean

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src ./src

CMD exec gunicorn --chdir src --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
