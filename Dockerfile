FROM python:3.11-slim

WORKDIR /app

# Copy the application
COPY hosts_manager.py /app/

# Make it executable
RUN chmod +x /app/hosts_manager.py

# Run the application
CMD ["python", "/app/hosts_manager.py"]
