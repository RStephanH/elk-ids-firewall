# Suricata configuration

After the installation via the script or command or building from code source make sure that you have the `NFQueue` and `AF_PACKET` support without that we can configure suricata in inline mode.
Check this out with this command :
```bash
sudo suricata --build-info
```
