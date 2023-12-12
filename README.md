# jenkins-job-builder

## usage

```
docker run --rm -it -v ./jobs:/jjb/jobs \
    -e JENKINS_USR=admin \
    -e JENKINS_PSW=jenkins \
    -e JENKINS_URL=https://jenkins.opsbox.dev \
    -e DRY_RUN=true \
    seanly/jenkins-job-builder
```