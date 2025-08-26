# Snort 3 

## Snort 3 Installation

## Step 1 Install the dependency 
```bash
./install_snort_dependencies.sh
```
## Step 2 Build and Install snort

```bash
./build_snort_with_gum.sh
```
> [!tip] Verify
> You can check your Build with the command : `sudo snort -v`

## pulledpork3

### pulledpork3 installation

```bash
git clone https://github.com/shirkdog/pulledpork3.git
cd pulledpork3

sudo mkdir /usr/local/etc/pulledpork/
sudo cp etc/pulledpork.conf /usr/local/etc/pulledpork/

sudo mkdir /usr/local/bin/pulledpork/
sudo cp pulledpork.py /usr/local/bin/pulledpork/
sudo cp -r lib/ /usr/local/bin/pulledpork/
```

### pulledpork3 configuration
Modify our pulledpork.conf file.
```bash
sudo vim /usr/local/etc/pulledpork3/pulledpork.conf
```
```
community_ruleset = true
registered_ruleset = false
LightSPD_ruleset = false
```
> [!TIP]
> Enter your oinkcode (line 8) from snort.org if you’re using the LightSPD_ruleset or registered_ruleset.

If you want to download and use blocklists, set one or both of the blocklists to true.
```
snort_blocklist = true
et_blocklist = true

```
PulledPork needs to know where your snort binary is located
```
snort_path = /usr/local/bin/snort
```
Where are your local rules saved
```
local_rules = /usr/local/etc/rules/local.rules
```
Now run PulledPork3:
```
sudo /usr/local/bin/pulledpork3/pulledpork.py -c /usr/local/etc/pulledpork3/pulledpork.conf
```
