/*
Copyright © 2021 NAME HERE <EMAIL ADDRESS>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// destroyCmd represents the destroy command
var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy SpaceONE from eks to spaceone package",
	Long:  `Long description`,
	Run: func(cmd *cobra.Command, args []string) {
		_setAwsCredentais()
		_setKubectlConfig()
		destroy()
	},
}

func init() {
	rootCmd.AddCommand(destroyCmd)
}

func destroy() {
	log.Println("Destroy SpaceONE")

	components := []string{"initialization", "deployment", "secret", "documentdb", "controllers", "eks", "certificate"}

	for _, component := range components {
		_executeTerraform(component, "destroy")
	}

	err := _removeHelmData()
	if err != nil {
		panic(err)
	}

	err = _removeTerraformData(&components)
	if err != nil {
		panic(err)
	}

	err = _removeGpgKeyBinary()
	if err != nil {
		panic(err)
	}

	err = _removeKubeConfig()
	if err != nil {
		panic(err)
	}

	log.Println("\nSpaceONE Destroy completed")

}

func _removeHelmData() error {
	initializerHelmValuePath := "./data/helm/values/spaceone-initializer/*"
	if files, err := filepath.Glob(initializerHelmValuePath); err == nil {
		for _, f := range files {
			if err := os.Remove(f); err != nil {
				return errors.Wrap(err, "Failed to delete spaceone-initailzer helm release values")
			}
		}
	}

	spaceoneHelmValuePath := "./data/helm/values/spaceone/*"
	if files, err := filepath.Glob(spaceoneHelmValuePath); err == nil {
		for _, f := range files {
			if err := os.Remove(f); err != nil {
				return errors.Wrap(err, "Failed to delete spaceone helm release values")
			}
		}
	}

	helmRepositoryConfig := "./data/helm/config/*"
	if files, err := filepath.Glob(helmRepositoryConfig); err == nil {
		for _, f := range files {
			if err := os.Remove(f); err != nil {
				return errors.Wrap(err, "Failed to delete helm repository config")
			}
		}
	}

	helmRepositoryCache := "./data/helm/cache/repository/*"
	if files, err := filepath.Glob(helmRepositoryCache); err == nil {
		for _, f := range files {
			if err := os.Remove(f); err != nil {
				return errors.Wrap(err, "Failed to delete helm repository cache")
			}
		}
	}

	return nil
}

func _removeTerraformData(components *[]string) error {
	for _, component := range *components {
		tfvar := fmt.Sprintf("./module/%s/%s.auto.tfvars", component, component)
		if _, err := os.Stat(tfvar); !os.IsNotExist(err) {
			if err = os.Remove(tfvar); err != nil {
				return errors.Wrap(err, "Failed to delete terraform auto vars")
			}
		}

		terraformState := fmt.Sprintf("./data/tfstates/%s.tfstate*", component)
		if files, err := filepath.Glob(terraformState); err == nil {
			for _, f := range files {
				if err := os.Remove(f); err != nil {
					return errors.Wrap(err, "Failed to delete terraform states")
				}
			}
		}
	}

	return nil
}

func _removeGpgKeyBinary() error {
	publicKeyBinary := "./module/secret/gpg/public-key-binary.gpg"
	if _, err := os.Stat(publicKeyBinary); !os.IsNotExist(err) {
		if err = os.Remove(publicKeyBinary); err != nil {
			return errors.Wrap(err, "Failed to delete gpg key binary")
		}
	}

	return nil
}

func _removeKubeConfig() error {
	kubeConfig := "./data/kubeconfig/config"
	if _, err := os.Stat(kubeConfig); !os.IsNotExist(err) {
		if err = os.Remove(kubeConfig); err != nil {
			return errors.Wrap(err, "Failed to delete kubeconfig")
		}
	}

	return nil
}
