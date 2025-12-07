# NCCL Multi-Node NVLink (MNNVL) and Rail Optimization

## Overview

NCCL includes advanced features for cross-machine topology awareness and rail optimization to maximize performance in multi-node GPU clusters.

## Cross-Machine Topology Awareness (MNNVL)

### What is MNNVL?

Multi-Node NVLink (MNNVL) is a feature that enables NCCL to understand and optimize communication patterns across multiple physical machines connected via NVLink. This provides:

- **Cross-machine topology detection**: Automatically discovers NVLink connections between GPUs across different nodes
- **Intelligent path selection**: Chooses optimal communication paths considering inter-node NVLink topology
- **Multi-node NVLink support**: Leverages high-bandwidth NVLink connections between machines

### Configuration Parameters

#### NCCL_MNNVL_ENABLE

Controls whether Multi-Node NVLink support is enabled.

```bash
export NCCL_MNNVL_ENABLE=<value>
```

Values:
- `0`: Disabled
- `1`: Force enable MNNVL
- `2`: Auto-detect (default) - enables MNNVL when multiple nodes are detected and P2P is available

#### NCCL_MNNVL_UUID

Sets the fabric UUID for MNNVL identification.

```bash
export NCCL_MNNVL_UUID=<value>
```

#### NCCL_MNNVL_CLIQUE_ID

Sets the clique ID for MNNVL fabric partitioning.

```bash
export NCCL_MNNVL_CLIQUE_ID=<value>
```

Values:
- `-2`: Auto-detect from hardware (reads rack serial, slot, tray information)
- `-1`: No specific clique ID
- Other values: Explicit clique ID

### Topology Path Types

NCCL defines various path types for different connection scenarios:

#### PATH_NVL (1)
Connection traversing NVLink between GPUs.

#### PATH_NVB (2)
Connection through NVLink using an intermediate GPU.

#### PATH_C2C (3)
Connection through Chip-to-Chip (C2C) links.

#### PATH_PXN (7)
**Rail-local aggregated network operations**: Connection between a GPU and a NIC using an intermediate GPU. This path type is specifically designed to enable rail-local, aggregated network send/recv operations for optimal bandwidth utilization.

#### PATH_PHB (8)
Connection traversing PCIe as well as a PCIe Host Bridge (typically the CPU).

#### PATH_SYS (9)
Connection traversing PCIe as well as the SMP interconnect between NUMA nodes (e.g., QPI/UPI).

#### PATH_NET (10)
Connection through the network.

## Rail Optimization

### What is Rail Optimization?

Rail optimization ensures that network traffic is distributed optimally across multiple network interfaces (rails) while minimizing cross-rail communication. This improves:

- **Bandwidth utilization**: Better use of available network links
- **Latency reduction**: Avoiding unnecessary cross-rail hops
- **Scalability**: Better performance with multiple NICs per node

### Configuration Parameters

#### NCCL_MNNVL_RAIL_PER_HOST

Controls whether rails are identified per-host in MNNVL systems.

```bash
export NCCL_MNNVL_RAIL_PER_HOST=<value>
```

Values:
- `0`: Disabled (default) - rails are identified globally by ASIC and port
- `1`: Enabled - in MNNVL systems with different hosts, rails are identified per host using PCI ID and port

When enabled, this parameter ensures that in multi-host MNNVL deployments:
- Each host's rails are treated independently
- Network interfaces on different hosts can use the same rail identifier if they have matching PCI IDs and ports
- Improves path selection for cross-machine communication

### Cross-NIC Communication

NCCL automatically detects and optimizes for systems with multiple network interfaces:

#### crossNic Modes

- **crossNic = 0**: All channels use the same NIC (same ASIC/port)
- **crossNic = 1**: Channels may use different NICs
- **crossNic = 2**: Channels deliberately alternate between NICs to balance load

#### Ring Alternation

For systems with `crossNic = 2`, NCCL alternates ring assignments to avoid crossing rails:

- Channels are paired (even/odd)
- Odd-numbered nodes exchange their ring assignments
- This ensures balanced traffic distribution across rails

Example configuration for a system with dual-rail network:
```bash
# Enable MNNVL with rail-per-host
export NCCL_MNNVL_ENABLE=2
export NCCL_MNNVL_RAIL_PER_HOST=1

# Let NCCL auto-detect optimal crossNic strategy
# The system will automatically use crossNic=2 when beneficial
```

## Implementation Details

### Topology Detection (src/graph/topo.h, topo.cc)

The topology system maintains:
- Node types: GPU, PCI, NVS (NVSwitch), CPU (NUMA), NIC, NET
- Link types and bandwidths for different connection technologies
- Pre-computed paths between all nodes
- System-wide and per-node topology information

### Path Selection (src/graph/paths.cc)

Path selection algorithm:
1. Computes all possible paths between source and destination
2. Considers bandwidth, latency, and path type
3. For PATH_PXN paths, identifies intermediate GPUs for aggregation
4. Selects optimal path based on communication pattern

### Network Search (src/graph/search.cc)

The search algorithm:
1. Checks network interface compatibility based on rail configuration
2. Applies MNNVL_RAIL_PER_HOST rules for cross-host scenarios
3. Validates path types against maximum allowed types
4. Ensures consistent rail usage within channel groups

### Connection Setup (src/graph/connect.cc)

Connection setup:
1. Allocates communication channels
2. Applies ring alternation for crossNic = 2 systems
3. Exchanges ring assignments for load balancing
4. Establishes optimized communication paths

## Usage Examples

### Example 1: Basic MNNVL Setup

For a system with NVLink connections between nodes:

```bash
# Enable MNNVL with auto-detection
export NCCL_MNNVL_ENABLE=2

# Run your application
mpirun -np 16 ./your_nccl_application
```

### Example 2: Multi-Rail Configuration

For a system with multiple NICs per node:

```bash
# Enable MNNVL
export NCCL_MNNVL_ENABLE=2

# Enable per-host rail identification
export NCCL_MNNVL_RAIL_PER_HOST=1

# Optional: Enable debug output to see topology decisions
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=GRAPH,NET

# Run your application
mpirun -np 32 ./your_nccl_application
```

### Example 3: Forcing Specific Topology

For testing or specific hardware configurations:

```bash
# Force enable MNNVL
export NCCL_MNNVL_ENABLE=1

# Set specific clique ID
export NCCL_MNNVL_CLIQUE_ID=100

# Enable rail per host
export NCCL_MNNVL_RAIL_PER_HOST=1

# Run your application
mpirun -np 64 ./your_nccl_application
```

## Performance Considerations

### When to Use MNNVL

MNNVL provides benefits when:
- Multiple nodes are connected via NVLink (e.g., GB200-NVL72 systems)
- High-bandwidth inter-node communication is required
- Workloads benefit from direct GPU-to-GPU communication across nodes

### When to Use Rail Optimization

Rail optimization is beneficial when:
- Multiple NICs are available per node
- Network bandwidth is a bottleneck
- Balanced traffic distribution improves performance
- Systems have heterogeneous network topologies

### Debugging

To debug topology and rail selection:

```bash
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,GRAPH,NET,COLL

# This will show:
# - Detected topology
# - Path selection decisions
# - Rail assignments
# - Channel allocations
```

## Hardware Support

### Supported Architectures

- NVIDIA Pascal (P100) - SM 6.0
- NVIDIA Volta (V100) - SM 7.0
- NVIDIA Ampere (A100, A30) - SM 8.0, 8.6
- NVIDIA Ada (RTX 40-series) - SM 8.9
- NVIDIA Hopper (H100, H200) - SM 9.0
- NVIDIA Blackwell (B100, B200, GB200) - SM 10.0

### NVLink Bandwidth by Generation

- Pascal (SM 6.0): 18.0 GB/s per link
- Volta (SM 7.0): 20.0 GB/s per link
- Ampere (SM 8.0): 20.0 GB/s per link
- Ampere (SM 8.6): 12.0 GB/s per link
- Hopper (SM 9.0): 20.6 GB/s per link
- Blackwell (SM 10.0): 40.1 GB/s per link

## References

- Source files:
  - `src/graph/topo.h` - Topology definitions and structures
  - `src/graph/topo.cc` - Topology construction and management
  - `src/graph/paths.cc` - Path computation and selection
  - `src/graph/search.cc` - Network search and rail optimization
  - `src/graph/connect.cc` - Connection setup and ring alternation
  - `src/init.cc` - MNNVL initialization and configuration

- Key parameters in code:
  - Line 557 in `src/graph/search.cc`: `NCCL_PARAM(MnnvlRailPerHost, "MNNVL_RAIL_PER_HOST", 0)`
  - Line 740 in `src/init.cc`: `NCCL_PARAM(MNNVLEnable, "MNNVL_ENABLE", 2)`
  - Line 83 in `src/graph/topo.h`: `#define PATH_PXN 7` - Rail-local aggregated operations

For more information, refer to the NCCL documentation at https://docs.nvidia.com/deeplearning/nccl/
