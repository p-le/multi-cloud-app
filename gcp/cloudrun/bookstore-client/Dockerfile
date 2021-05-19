FROM python:3.8-slim

ENV PYTHONUNBUFFERED True

WORKDIR /app
COPY . ./
RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT [ "python", "client.py" ]
