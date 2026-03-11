# Use official Python runtime as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy Python files
COPY *.py ./

# Expose port for TCP server
EXPOSE 8080

# Run gateway when container starts
CMD ["python3", "main.py"]