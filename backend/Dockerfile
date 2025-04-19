FROM python:3.12-slim

RUN apt-get update && apt-get upgrade -y && apt-get clean

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app/ ./app
COPY certs/ /certs/

EXPOSE 5000

CMD ["python", "app/main.py"]
