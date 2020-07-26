FROM gcr.io/google-appengine/python

RUN virtualenv -p python3.7 /env 

ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

ADD requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

ADD main.py /app/main.py

# Configure file logger log folder.
ENV LOG_FOLDER /var/log/app
RUN mkdir -p /var/log/app

CMD gunicorn -b :$PORT main:app