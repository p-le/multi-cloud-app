# Local Test
Port should match with EXPOSE <PORT> in Dockerfile
```
eb local run --port 8000
eb local open
```

# Create env
After testing application locally, deploy to Elastic Beanstalk
```
eb create <ENV>
eb create dev-env
eb open
```

# Terminate Env
```
eb terminate <ENV>
eb terminate dev-env
```

# Others

Checking/select Platform
```
eb platform show
eb platform select
```
