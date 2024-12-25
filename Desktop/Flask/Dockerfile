FROM python:3.10-alpine3.15

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY src src

# Expose application port
EXPOSE 5000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl --fail http://localhost:5000/health || exit 1

# Entrypoint for the container
ENTRYPOINT ["python", "./src/app.py"]
