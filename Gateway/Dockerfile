# Use official Python runtime as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install PostgreSQL client library for psycopg2
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir psycopg2-binary

# Copy Python files
COPY *.py ./

# Expose port for TCP server
EXPOSE 8080

# Run gateway when container starts
CMD ["python3", "main.py"]