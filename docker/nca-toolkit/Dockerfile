FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone the NCA Toolkit repository
RUN git clone https://github.com/stephengpope/no-code-architects-toolkit .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 8010

# Command to run the application
CMD ["python", "app.py"]
