FROM python:3.12-slim

RUN mkdir /app

COPY ./app.py /app

RUN pip install prometheus_client

EXPOSE 8000

ENTRYPOINT ["python3","/app/app.py"]
