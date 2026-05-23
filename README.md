## UVM CNN Verification Project

## Overview

This repository contains a SystemVerilog based UVM testbench developed for verifying a CNN 2D convolution layer implementation.


The repository includes:

* CNN RTL/VHDL design files
* Reference model implementation
* Testbench and scoreboard structure
*  Universal Verification Components (UVCs)

---

## Repository Structure

### cnn_conv2d_layer/

Contains the CNN convolution layer RTL/VHDL implementation files.

Important files include:

* `cnn_conv2d_layer.vhd`
* `cnn_conv2d_unit.vhd`
* `fixed_multiplier.vhd`
* `shift_reg.vhd`


---

### reference_model/

Contains the reference model and related usage examples used for functional comparison and output checking.

Additional documentation:

* `REFERENCE_MODEL_USAGE.md`

---

### uvc/

The folders clock_uvc, reset_uvc and cnn_conv2d_layer_uvc contains the SystemVerilog files for UVCs built for the project

The folder:

* `cnn_conv2d_layer_my_uvc_attempt`

contains an experimental UVC for the CNN Convolution Layer I developed during the project exploration phase.

This includes:

* input agent
* output agent , both of them contain;
  * monitors
  * drivers
  * sequence items
  * configuration classes
  * interface files

Detailed explanations and implementation comments are included directly inside the source files.



fcover_report.txt : Functional Coverage Report
---

## Verification Features

The repository demonstrates:

* modular verification structure
* stimulus generation in both directed and constrained random manner
* scoreboard-based checking


---

## Languages and Methodologies

* SystemVerilog
* Constrained Random Verification (CRV)

---

## Notes

This repository is primarily intended as a learning project.

---


