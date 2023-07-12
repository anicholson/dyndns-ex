# dyndns

A barebones Dynamic DNS client that reports to AWS Route53, written in Elixir.
Untested, works-for-me software.

## Usage via Docker

To run this via Docker do the following:

```bash
$ docker build -it dyndns .
$ docker run --name dyndns -e HOSTNAME={your hostname} -e HOSTED_ZONE_ID={the hosted zone id from Route53} -e AWS_ACCESS_KEY_ID={your AWS key} -e AWS_SECRET_ACCESS_KEY={your AWS secret key}
```