# Security warning: this uses the DockerHub base image.
# If your threat model includes supply-chain attacks capable of subverting
# high-value accounts on DockerHub, build your own base image.
# I mean, it probably doesn't though, let's be honest.

FROM python:3-alpine

WORKDIR /usr/src/app

RUN apk update && apk upgrade

COPY python/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY python/* ./

# -u means unbuffered logs https://stackoverflow.com/a/29745541
CMD [ "python", "-u", "./import_futel_data.py" ]
