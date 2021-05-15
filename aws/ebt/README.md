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

# Update application
```
eb deploy
```

# Management
```
eb config save <ENV> --cfg <CONFIG>
eb config save dev-env --cfg dev-env-configuration
eb config save dev-env --cfg dev-env-configuration-v2
```
Update config
```
eb config put dev-env-configuration-v2
eb config dev-env --cfg dev-env-configuration-v2
```

# Terminate Env
```
eb terminate <ENV>
eb terminate dev-env
```

# Others
Set Environment Variables
```
eb setenv <ENV_KEY>=<ENV_VALUE>
```

Checking/select Platform
```
eb platform show
eb platform select
```
