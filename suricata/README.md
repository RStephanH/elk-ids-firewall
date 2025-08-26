# Suricata configuration

## 1- Check your build info

After the installation via the script or command or building from code source make sure that you have the `NFQueue` and `AF_PACKET` support without that we can configure suricata in inline mode.
Check this out with this command :
```bash
sudo suricata --build-info
```

## 2- Basic setup 
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


## 3- Filebeat
You need Elasticsearch for storing and searching your data, and Kibana for visualizing and managing it.

To install and run Elasticsearch and Kibana, see [Installing the Elastic Stack](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/installing-elasticsearch).

### Step 1: Install Filebeat

Install Filebeat on all the servers you want to monitor.

To download and install Filebeat, use the commands that work with your system:

 DEB

```shell
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-9.1.2-amd64.deb
sudo dpkg -i filebeat-9.1.2-amd64.deb
```

### Step 2: Connect to the Elastic Stack

Connections to Elasticsearch and Kibana are required to set up Filebeat.

Set the connection information in `filebeat.yml`.

 Elastic Cloud Hosted  Self-managed

1. Set the host and port where Filebeat can find the Elasticsearch installation, and set the username and password of a user who is authorized to set up Filebeat. For example:
    
    ```yaml
    output.elasticsearch:
      hosts: ["https://myEShost:9200"]
      username: "filebeat_internal"
      password: "YOUR_PASSWORD"
    ```


### Step 3: Collect log data

There are several ways to collect log data with Filebeat but in our case we'll only this method:

- Data collection modules — simplify the collection, parsing, and visualization of common log formats

#### Enable and configure data collection modules

1. Identify the modules you need to enable. To see a list of available [modules](https://www.elastic.co/docs/reference/beats/filebeat/filebeat-modules), run:
    
     DEB
    
    ```sh
    filebeat modules list
    ```

- From the installation directory, enable suricata modules. For example, the following command enables the `nginx` module config:
    
     DEB
    
    ```sh
    filebeat modules enable suricata
    ```
   
    ```yaml
    - module: suricata
      access:
        enabled: true
        var.paths: ["/var/log/suricata/eve.json"]
    ```
    



>[!Tip]
>To test your configuration file, change to the directory where the Filebeat binary is installed, and run Filebeat in the foreground with the following options specified: `./filebeat test config -e`. 

### Step 4: Set up assets

Filebeat comes with predefined assets for parsing, indexing, and visualizing your data. To load these assets:

1. Make sure the user specified in `filebeat.yml` is [authorized to set up Filebeat](https://www.elastic.co/docs/reference/beats/filebeat/privileges-to-setup-beats).
    
2. From the installation directory, run:
    
     DEB
    
    ```sh
    filebeat setup -e
    ```
    


>[!Note]
>Filebeat should not be used to ingest its own log as this may lead to an infinite loop.

### Step 5: Start Filebeat

Before starting Filebeat, modify the user credentials in `filebeat.yml` and specify a user who is authorized to publish events

To start Filebeat, run:

 DEB

```sh
sudo systemctl start filebeat
```

### Step 6: View your data in Kibana

Filebeat comes with pre-built Kibana dashboards and UIs for visualizing log data. You loaded the dashboards earlier when you ran the `setup` command.

To open the dashboards:

1. Launch Kibana:
    
     Elastic Cloud Hosted  Self-managed
    
    Point your browser to [http://localhost:5601](http://localhost:5601), replacing `localhost` with the name of the Kibana host.
    
2. In the side navigation, click **Discover**. To see Filebeat data, make sure the predefined `filebeat-*` data view is selected.
    

 >[!Tip]
 >If you don’t see data in Kibana, try changing the time filter to a larger range. By default, Kibana shows the last 15 minutes.
> - In the side navigation, click **Dashboard**, then select the dashboard that you want to open.
 
