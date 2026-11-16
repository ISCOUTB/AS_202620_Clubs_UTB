FROM python:3.12-slim

WORKDIR /app

ENV PYTHONPATH=/app/src \
    PYTHONUNBUFFERED=1 \
    TMPDIR=/app/tmp

RUN useradd -m -u 1000 appuser \
    && mkdir -p /app/tmp /app/uploads \
    && chown -R appuser:appuser /app

COPY requirements.txt .
# NOSONAR
RUN pip install --no-cache-dir --only-binary :all: -r requirements.txt

COPY src/ ./src/
COPY migrations/ ./migrations/

# NOSONAR
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "src.linkclub.main:app", "--host", "0.0.0.0", "--port", "8000"]