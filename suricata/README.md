# Suricata configuration

1- Check your build info

After the installation via the script or command or building from code source make sure that you have the `NFQueue` and `AF_PACKET` support without that we can configure suricata in inline mode.
Check this out with this command :
```bash
sudo suricata --build-info
```

2- Basic setup 
Define your $HOME_NET variable and in wich interface you want to inspect in `/etc/suricata/suricata.yaml`
In this configuration I use NFQueue Mode so I have this kind of configuration in `/etc/suricata/suricata.yaml` 
```yaml
af-packet:
  - interface: eth0
    cluster-id: 99
    cluster-type: cluster_flow
    copy-mode: ips

  - interface: eth1
    cluster-id: 100
    cluster-type: cluster_flow
    copy-mode: ips

```
>[!note]
>The order of interfaces in `suricata.yaml` does **not** affect functionality. Just make sure each has a unique `cluster-id` and the system routing is configured correctly.

By default Suricata just sniffs IDS mode (default), even if you set copy-mode: ips, then you must tell Suricata to run inline when starting it.

```bash
sudo suricata -c /etc/suricata/suricata.yaml -q 0
```
If you’re using the packaged version (Ubuntu/Debian/Kali/etc.), the service by default launches Suricata without the `-q 0` flag, so Stop the service and run it manually with the command above.If you want to use systemd service , you can edit the systemd service file override.


>[!note]
>Since we’re in router mode:
> - eth0 is our LAN side (default gateway for clients).
> - eth1 is our WAN side (uplink).
>Linux must have IP forwarding enabled:
>```bash
>sysctl -w net.ipv4.ip_forward=1
>```
> - iptables/nftables rules must send the traffic into the queue and allow forwarding traffic between interfaces when suricata is down (closefail).
> ```bash
>sudo iptables -A FORWARD -i eth0 -o eth1 -j NFQUEUE --queue-bypass
>sudo iptables -A FORWARD -i eth1 -o eth0 -j NFQUEUE --queue-bypass
>
>```
> - Check it with the command : `sudo iptables -L FORWARD -v -n`

>[!note]
>Now, we can test it by creating a personalized rule in `/etc/suricata/rules/local.rules` and run suricata
