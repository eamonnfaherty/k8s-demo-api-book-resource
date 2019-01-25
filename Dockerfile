FROM python:3.7.2-alpine3.8

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
EXPOSE 8000

COPY requirements.txt /usr/src/app/
RUN pip install -r requirements.txt

COPY src/* /usr/src/app/
CMD [ "hug", "-f", "api.py" ]
