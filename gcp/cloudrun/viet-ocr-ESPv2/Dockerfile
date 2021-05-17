FROM python:3.8-slim AS grpc-tools-base
WORKDIR /protos

COPY protos .
RUN pip install --no-cache-dir grpcio-tools==1.37.1 && \
    python -m grpc_tools.protoc -I./ --python_out=. --grpc_python_out=. ./helloworld.proto


FROM python:3.8-slim
ENV PYTHONUNBUFFERED True

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src ./src
COPY --from=grpc-tools-base /protos/*.py ./src/

ENTRYPOINT [ "python" ]
CMD [ "src/main.py" ]
