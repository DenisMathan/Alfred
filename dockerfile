FROM python:3.11.6

WORKDIR /app

COPY requirements.txt ./
RUN pip install --upgrade pip --no-cache-dir
RUN pip install -r requirements.txt --no-cache-dir
RUN pip install gunicorn

COPY . .

# CMD ["python", "app.py"]

# CMD ["gunicorn", "-w" "4", "wsgi:app", "0.0.0.0:3333"]
EXPOSE 3333

CMD ["sh", "./start.sh"]
