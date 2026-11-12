# Tailscale 出口节点部署

在仓库的 `ansible/` 目录操作，提前安装 Ansible，并确保能通过
`aether` 用户和现有 SSH 密钥连接节点。执行时需要节点的 sudo 密码。

## 1. 确认节点清单

编辑 [inventories/tailscale/hosts.yaml](../inventories/tailscale/hosts.yaml)，使用节点域名。

- `tailscale_login_server`：当前 backup 节点使用自建 Headscale，其余使用 Tailscale 官方服务。
- `tailscale_source_policy_enabled`：普通出口设为 `false`；当前四台使用专用源地址方案，设为 `true`。
- `tailscale_subnet_routes`：填写该节点需要发布的子网；省略则保留现有设置，`[]` 表示清空。

## 2. 安装

先部署一台，例如：

```sh
ANSIBLE_ASK_PASS=false ansible-playbook \
  -i inventories/tailscale/hosts.yaml playbooks/tailscale_nodes.yaml \
  --limit tailscale-backup-exit-node-1.corp.aetherrootr.com -K --diff
```

安装只准备软件、配置和启动脚本。认证与首次启动由维护者完成。
部署全部四台时移除 `--limit` 参数；sudo 密码不同时逐台部署。

## 3. 准备源地址并启动

通过 SSH 登录刚部署的节点：

```sh
ssh -t aether@tailscale-backup-exit-node-1.corp.aetherrootr.com
```

仅在 `tailscale_source_policy_enabled: true` 时需要以下准备：

1. 手工将分配给该节点的专用 IPv4、IPv6 配置到出口网卡，并持久化。
   IPv6 专用地址设置 `preferred_lft 0`，避免被普通连接默认选用。
2. 运行 `sudoedit /etc/default/tailscale-source`，写入以下内容并替换占位值：

   ```sh
   SOURCE_IPV4=REPLACE_WITH_DEDICATED_IPV4
   SOURCE_IPV6=REPLACE_WITH_DEDICATED_IPV6
   ```

在节点上执行：

```sh
~/start-tailscale-node.sh
```

按提示输入 sudo 密码，并在需要时打开登录链接完成认证。
若提示登录服务器不匹配，先核对清单与节点现有账号。

## 4. 确认可用

运行 `tailscale status`，在对应控制端批准出口及子网路由。
客户端选择该出口，检查网页和内网访问，再按相同步骤部署其余节点。

源地址和路由器规则均由维护者手工管理。可以先启用节点策略，再配置路由器；
衔接期间可能短暂断网。路由器配套完成后，再验证 IPv4、IPv6 和 WebRTC 出口。
