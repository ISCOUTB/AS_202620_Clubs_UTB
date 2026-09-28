FROM python:3.11-slim

WORKDIR /app

RUN useradd -m -u 1000 appuser

COPY requirements.txt .

RUN pip install --no-cache-dir --only-binary :all: -r requirements.txt

COPY src/ ./src/

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "src.linkclub.main:app", "--host", "0.0.0.0", "--port", "8000"]
