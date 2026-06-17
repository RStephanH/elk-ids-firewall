package main

import (
	"os"

	"github.com/charmbracelet/log"

	"ovsController/utils"
)

func main() {
	log.Info("Starting OVS Controller")
	log.Info("This app will ask for the IDS vnet interface name to monitor.")

	if err := utils.EnsureOvsInstalled(); err != nil {
		log.Error("OVS is not installed or ovs-vsctl not found", "error", err)
		os.Exit(1)
	}
	log.Info("OVS is installed")

	vnet, err := utils.PromptVnet()
	if err != nil {
		log.Error("Failed to read vnet interface", "error", err)
		os.Exit(1)
	}

	log.Info("Vnet selected", "vnet", vnet)

	if err := utils.ShowBridgeState(); err != nil {
		log.Error("Failed to show bridge state", "error", err)
		os.Exit(1)
	}

	if err := utils.ShowVmInterfaces(); err != nil {
		log.Error("Failed to list IDS VM interfaces", "error", err)
		os.Exit(1)
	}

	if err := utils.ShowBridgePorts(); err != nil {
		log.Error("Failed to list bridge ports", "error", err)
		os.Exit(1)
	}

	if err := utils.ClearMirror(); err != nil {
		log.Error("Failed to clear existing mirror", "error", err)
		os.Exit(1)
	}

	if err := utils.CreateMirror(vnet); err != nil {
		log.Error("Failed to create mirror", "error", err)
		os.Exit(1)
	}

	if err := utils.VerifyMirror(); err != nil {
		log.Error("Failed to verify mirror state", "error", err)
		os.Exit(1)
	}
}
