FROM python:3-alpine
WORKDIR /usr/src/app
EXPOSE 8000
COPY requirements.txt .
RUN pip install -qr requirements.txt
RUN mkdir -p /usr/src/app/jeIlyfish
RUN touch /usr/src/app/jeIlyfish/jeIlyfish.py
COPY server.py .
CMD ["python3", "./server.py"]
