FROM python:3.8-slim

ENV PYTHONUNBUFFERED True

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src protos/helloworld/generated_pb2/*.py /app/src/

ENTRYPOINT [ "python" ]
CMD [ "src/main.py" ]
