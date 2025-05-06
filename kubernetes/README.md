# Kubernetes

---

Based on [grafana tanka](https://github.com/grafana/tanka) management configuration.
[Document](https://tanka.dev/)

## Initialize the local environment
Install tanka cli and jb
for x86-64
```
sudo curl -Lo /usr/local/bin/tk https://github.com/grafana/tanka/releases/latest/download/tk-linux-amd64
sudo chmod a+x /usr/local/bin/tk

sudo curl -Lo /usr/local/bin/jb https://github.com/jsonnet-bundler/jsonnet-bundler/releases/latest/download/jb-linux-amd64
sudo chmod a+x /usr/local/bin/jb

# Configuration completion requires restarting the shell to take effect
tk complete
```

for Macos
```
brew install tanka

brew install jsonnet-bundler

# Configuration completion requires restarting the shell to take effect
tk complete
```
