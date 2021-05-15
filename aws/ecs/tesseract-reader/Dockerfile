FROM python:3.8-alpine

WORKDIR /app

RUN apk update && \
    apk add --no-cache \
        musl-dev \
        gcc \
        jpeg-dev \
        zlib-dev \
        tesseract-ocr

ADD https://github.com/tesseract-ocr/tessdata/raw/master/vie.traineddata /usr/share/tessdata/vie.traineddata
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
