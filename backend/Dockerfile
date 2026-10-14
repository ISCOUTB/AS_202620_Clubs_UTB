FROM python:3.12-slim

WORKDIR /app

ENV PYTHONPATH=/app/src \
    PYTHONUNBUFFERED=1

RUN useradd -m -u 1000 appuser

COPY requirements.txt .
RUN pip install --no-cache-dir --only-binary :all: -r requirements.txt

COPY src/ ./src/
COPY migrations/ ./migrations/

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "linkclub.main:app", "--host", "0.0.0.0", "--port", "8000"]
