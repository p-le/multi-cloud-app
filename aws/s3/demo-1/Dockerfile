FROM python:3.8-alpine

WORKDIR /app

COPY requirements.txt .
COPY main.py .
RUN pip install --no-cache-dir -r requirements.txt


ENTRYPOINT [ "python" ]
CMD [ "main.py" ]
