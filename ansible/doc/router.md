# Soft router

---

## Overview
Deploying soft routers in the private sector is a measure to improve the Internet experience. Currently we have chosen the soft routing solution provided by [gl.inet](https://www.gl-inet.com/), we have chosen two models of routers [gl-axt1800](https://www.gl-inet.com/products/gl-axt1800/) and [gl-a1300](https://www.gl-inet.com/products/gl-a1300/). We deployed openclash on the soft router to bypass GFW's censorship and golinks to provide Google-like go/links services.

## Set for gl-axt1800

Run the command to deploy golinks and openclash on the soft route:

```
ansible-playbook -i inventories/router/ playbooks/router_gl_axt1800.yaml -u root --ask-become-pass
```

## Set for gl-a1300

Run the command to deploy golinks and openclash on the soft route:

```
ansible-playbook -i inventories/router/ playbooks/router_gl_a1300.yaml -u root --ask-become-pass
```

## Remove CN restrictions (very dangerous)

```
echo "US" |dd of=/dev/mtdblock8 bs=1 seek=152
sync
reboot
```