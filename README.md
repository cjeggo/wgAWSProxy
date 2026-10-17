# aws_proxy

Stands up a disposable WireGuard relay in a personal AWS account, so scan/exploit
traffic egresses from the jump VM's IP instead of thor's. Personal AWS account
only.

State is local (`terraform.tfstate` in this directory) - no remote backend, no
pipeline. Treat this box as disposable: apply before an engagement, destroy
after.

## Usage

```
cp terraform.tfvars.example terraform.tfvars   # fill in real values, never commit
terraform init
terraform plan
terraform apply
```

Then, locally:

```
terraform output -raw thor_wg_config | sudo tee /etc/wireguard/wg0.conf
sudo wg-quick up wg0
curl ifconfig.me   # should now show the jump VM's IP, not thor's
```

Full tunnel by default - `AllowedIPs = 0.0.0.0/0` in the generated client
config routes everything through it. Deliberate for engagements (targets like
CloudFront/Cloudflare-fronted sites rotate IPs, so pinning to specific
addresses breaks); narrow it only for a quick, scoped test against a fixed IP.

**IPv6 kill switch, baked into the generated config's PostUp/PostDown:**
`AllowedIPs = 0.0.0.0/0` only covers IPv4. Without a corresponding IPv6
control, any AAAA-resolving target would leak thor's real IPv6 address
straight around the tunnel - the WireGuard route simply wouldn't apply to
it. `PostUp` disables IPv6 system-wide (`sysctl
net.ipv6.conf.all.disable_ipv6=1`) the moment the tunnel comes up; `PostDown`
re-enables it on teardown. Fail-closed: if IPv6 can't be tunneled, it's
blocked outright rather than silently leaking.

**While the tunnel is up, everything routes through the jump VM's
IP, not just engagement traffic** - unrelated SSH sessions, `git pull`,
package updates, all of it. Don't use thor for anything else during a live
engagement window.

Tear down after use:

```
sudo wg-quick down wg0
terraform destroy
```
