You need Elasticsearch for storing and searching your data, and Kibana for visualizing and managing it.

To install and run Elasticsearch and Kibana, see [Installing the Elastic Stack](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/installing-elasticsearch).

## Step 1: Install Filebeat

Install Filebeat on all the servers you want to monitor.

To download and install Filebeat, use the commands that work with your system:

 DEB

```shell
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-9.1.2-amd64.deb
sudo dpkg -i filebeat-9.1.2-amd64.deb
```

## Step 2: Connect to the Elastic Stack

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


## Step 3: Collect log data

There are several ways to collect log data with Filebeat but in our case we'll only this method:

- Data collection modules — simplify the collection, parsing, and visualization of common log formats

### Enable and configure data collection modules

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

## Step 4: Set up assets

Filebeat comes with predefined assets for parsing, indexing, and visualizing your data. To load these assets:

1. Make sure the user specified in `filebeat.yml` is [authorized to set up Filebeat](https://www.elastic.co/docs/reference/beats/filebeat/privileges-to-setup-beats).
    
2. From the installation directory, run:
    
     DEB
    
    ```sh
    filebeat setup -e
    ```
    


>[!Note]
>Filebeat should not be used to ingest its own log as this may lead to an infinite loop.

## Step 5: Start Filebeat

Before starting Filebeat, modify the user credentials in `filebeat.yml` and specify a user who is authorized to publish events

To start Filebeat, run:

 DEB

```sh
sudo systemctl start filebeat
```

## Step 6: View your data in Kibana

Filebeat comes with pre-built Kibana dashboards and UIs for visualizing log data. You loaded the dashboards earlier when you ran the `setup` command.

To open the dashboards:

1. Launch Kibana:
    
     Elastic Cloud Hosted  Self-managed
    
    Point your browser to [http://localhost:5601](http://localhost:5601), replacing `localhost` with the name of the Kibana host.
    
2. In the side navigation, click **Discover**. To see Filebeat data, make sure the predefined `filebeat-*` data view is selected.
    

 >[!Tip]
 >If you don’t see data in Kibana, try changing the time filter to a larger range. By default, Kibana shows the last 15 minutes.
> - In the side navigation, click **Dashboard**, then select the dashboard that you want to open.
 
