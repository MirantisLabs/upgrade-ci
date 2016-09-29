<img src="http://jenkins-ci.org/sites/default/files/jenkins_logo.png"/>


# Usage

```
# For ubuntu 16.04
dpkg -l docker.io || sudo apt install -y docker.io
git clone https://github.com/MirantisLabs/upgrade-ci
cd upgrade-ci/docker
sudo docker build -t upgrade-ci .
sudo docker run -d -p 0.0.0.0:8080:8080 -v jenkins_home:/var/jenkins_home upgrade-ci:latest
```
