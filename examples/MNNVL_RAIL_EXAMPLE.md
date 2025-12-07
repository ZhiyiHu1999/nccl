# MNNVL and Rail Optimization Example

This example demonstrates how to configure and use NCCL's Multi-Node NVLink (MNNVL) and Rail Optimization features.

## Overview

The `mnnvl_rail_optimization_example.sh` script provides practical examples of different configuration scenarios for multi-node NCCL deployments with cross-machine topology awareness and rail optimization.

## Running the Example

Simply execute the script to see all example configurations:

```bash
# Make the script executable (if not already)
chmod +x mnnvl_rail_optimization_example.sh

# Run the script
./mnnvl_rail_optimization_example.sh
```

## What Does This Example Show?

The script demonstrates:

1. **Basic MNNVL Setup**: Standard multi-node configuration with auto-detection
2. **Rail-Per-Host Configuration**: Managing independent rails per host in multi-NIC systems
3. **Forced MNNVL**: Explicitly enabling MNNVL with specific clique IDs
4. **Debug Mode**: How to analyze topology detection and path selection
5. **Verification**: How to confirm MNNVL is active
6. **Environment Variables**: Complete reference of configuration options

## Key Features Demonstrated

### Cross-Machine Topology Awareness (MNNVL)

MNNVL enables NCCL to:
- Detect NVLink connections between GPUs across different physical machines
- Optimize communication paths considering inter-node topology
- Utilize high-bandwidth NVLink for cross-machine GPU communication

### Rail Optimization

Rail optimization:
- Distributes network traffic across multiple NICs (rails)
- Minimizes cross-rail communication
- Uses PATH_PXN for rail-local aggregated network operations
- Alternates rings to balance load when `crossNic=2`

## Environment Variables

### MNNVL Configuration

- `NCCL_MNNVL_ENABLE`: Enable/disable MNNVL (0=off, 1=force, 2=auto)
- `NCCL_MNNVL_UUID`: Fabric UUID for identification
- `NCCL_MNNVL_CLIQUE_ID`: Clique ID for fabric partitioning
- `NCCL_MNNVL_RAIL_PER_HOST`: Rail identification scope (0=global, 1=per-host)

### Debug Configuration

- `NCCL_DEBUG`: Logging level (VERSION, WARN, INFO, TRACE)
- `NCCL_DEBUG_SUBSYS`: Subsystems to debug (INIT, GRAPH, NET, COLL, ALL)
- `NCCL_DEBUG_FILE`: Output file for debug logs

## Verifying MNNVL is Active

When MNNVL is enabled, you should see messages like:

```
NCCL INFO MNNVL busId 0x... fabric UUID ... cliqueId ...
NCCL INFO comm ... MNNVL 1
```

To see detailed topology information:

```bash
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,GRAPH
```

Look for references to:
- `PATH_PXN`: Rail-local aggregated network operations
- `crossNic`: Multi-NIC configuration mode
- NVLink paths between nodes

## Hardware Requirements

These features are beneficial for:
- Multi-node systems with NVLink connections (e.g., GB200-NVL72)
- Systems with multiple NICs per node
- High-performance computing clusters with advanced network topologies

## Supported Architectures

- NVIDIA Pascal (P100) - SM 6.0
- NVIDIA Volta (V100) - SM 7.0
- NVIDIA Ampere (A100, A30) - SM 8.0, 8.6
- NVIDIA Ada (RTX 40-series) - SM 8.9
- NVIDIA Hopper (H100, H200) - SM 9.0
- NVIDIA Blackwell (B100, B200, GB200) - SM 10.0

## Further Reading

For comprehensive documentation, see:
- [MNNVL_AND_RAIL_OPTIMIZATION.md](../MNNVL_AND_RAIL_OPTIMIZATION.md) - English version
- [MNNVL_AND_RAIL_OPTIMIZATION_CN.md](../MNNVL_AND_RAIL_OPTIMIZATION_CN.md) - Chinese version

## Source Code References

The implementation can be found in:
- `src/graph/topo.h` - Topology definitions and PATH_PXN
- `src/graph/search.cc` - MNNVL_RAIL_PER_HOST parameter (line 557)
- `src/graph/connect.cc` - Ring alternation for rail optimization (line 392)
- `src/init.cc` - MNNVL initialization (line 740)
