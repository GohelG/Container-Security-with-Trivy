# Use a minimal and secure base image
FROM python:3.9-slim

# Create a non-root user
RUN adduser --disabled-password --gecos '' flaskuser

# Set working directory
WORKDIR /app

# Copy only requirements first (layer caching)
COPY requirements.txt .

# Install dependencies with pip safely
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Use non-root user
USER flaskuser

# Expose only required port
EXPOSE 5000

# Run the Flask app
CMD ["python", "app.py"]
