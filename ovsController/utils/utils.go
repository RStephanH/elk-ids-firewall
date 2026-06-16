package utils

import (
	"bufio"
	"errors"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/log"
)

func EnsureOvsInstalled() error {
	_, err := exec.LookPath("ovs-vsctl")
	return err
}

func PromptVnet() (string, error) {
	log.Info("Enter vnet interface name")
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return "", err
	}

	vnet := strings.TrimSpace(input)
	if vnet == "" {
		return "", errors.New("vnet interface cannot be empty")
	}

	return vnet, nil
}

func ShowBridgeState() error {
	log.Info("Step 1: Show current OVS bridge state")
	output, err := runCommand("ovs-vsctl", "show")
	if err != nil {
		return logCommandError("ovs-vsctl show", output, err)
	}
	log.Info("OVS bridge state", "output", output)
	return nil
}

func ShowVmInterfaces() error {
	log.Info("Step 2: List IDS VM interfaces")
	output, err := runCommand("virsh", "domiflist", "ids")
	if err != nil {
		return logCommandError("virsh domiflist ids", output, err)
	}
	log.Info("IDS VM interfaces", "output", output)
	return nil
}

func ShowBridgePorts() error {
	log.Info("Step 2: List OVS bridge ports")
	output, err := runCommand("ovs-vsctl", "list-ports", "br0")
	if err != nil {
		return logCommandError("ovs-vsctl list-ports br0", output, err)
	}
	log.Info("OVS bridge ports", "output", output)
	return nil
}

func ClearMirror() error {
	log.Info("Step 3: Clear existing mirrors on br0")
	output, err := runCommand("ovs-vsctl", "clear", "Bridge", "br0", "mirrors")
	if err != nil {
		return logCommandError("ovs-vsctl clear Bridge br0 mirrors", output, err)
	}
	if output != "" {
		log.Info("Mirror clear output", "output", output)
	}
	log.Info("Mirror cleared")
	return nil
}

func CreateMirror(vnet string) error {
	log.Info("Step 4: Create mirror to IDS vnet", "vnet", vnet)
	output, err := runCommand(
		"ovs-vsctl",
		"--",
		"--id=@mirror-port",
		"get",
		"Port",
		vnet,
		"--",
		"--id=@m",
		"create",
		"Mirror",
		"name=ids-mirror",
		"select-all=true",
		"output-port=@mirror-port",
		"--",
		"set",
		"Bridge",
		"br0",
		"mirrors=@m",
	)
	if err != nil {
		return logCommandError("ovs-vsctl create mirror", output, err)
	}
	if output != "" {
		log.Info("Mirror creation output", "output", output)
	}
	log.Info("Mirror created", "vnet", vnet)
	return nil
}

func VerifyMirror() error {
	log.Info("Step 5: Verify mirror state")
	mirrorOutput, err := runCommand("ovs-vsctl", "list", "Mirror")
	if err != nil {
		return logCommandError("ovs-vsctl list Mirror", mirrorOutput, err)
	}
	log.Info("Mirror list", "output", mirrorOutput)

	bridgeOutput, err := runCommand("ovs-vsctl", "show")
	if err != nil {
		return logCommandError("ovs-vsctl show", bridgeOutput, err)
	}
	log.Info("OVS bridge state", "output", bridgeOutput)
	return nil
}

func runCommand(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	output, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(output)), err
}

func logCommandError(command, output string, err error) error {
	if output != "" {
		log.Error("Command failed", "command", command, "output", output, "error", err)
		return err
	}
	log.Error("Command failed", "command", command, "error", err)
	return err
}
