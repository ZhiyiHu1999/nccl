#!/bin/bash

# Example script demonstrating how to enable and test MNNVL and Rail Optimization features
# This script shows different configuration scenarios for multi-node NCCL deployments

echo "=================================================="
echo "NCCL MNNVL and Rail Optimization Example"
echo "=================================================="
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Example 1: Basic MNNVL with auto-detection
example_1_basic_mnnvl() {
    print_section "Example 1: Basic MNNVL Setup"
    
    echo "Configuration:"
    echo "  - NCCL_MNNVL_ENABLE=2 (auto-detect)"
    echo "  - Default settings for other parameters"
    echo ""
    echo "Use case: Standard multi-node setup with NVLink between nodes"
    echo ""
    echo "Command:"
    echo "  export NCCL_MNNVL_ENABLE=2"
    echo "  export NCCL_DEBUG=INFO"
    echo "  export NCCL_DEBUG_SUBSYS=INIT,GRAPH"
    echo "  mpirun -np 16 -hosts node1,node2 ./your_nccl_application"
    echo ""
}

# Example 2: MNNVL with rail-per-host for multi-rail systems
example_2_rail_per_host() {
    print_section "Example 2: MNNVL with Rail-Per-Host"
    
    echo "Configuration:"
    echo "  - NCCL_MNNVL_ENABLE=2"
    echo "  - NCCL_MNNVL_RAIL_PER_HOST=1"
    echo "  - Multiple NICs per node"
    echo ""
    echo "Use case: Multi-node system with multiple NICs per node"
    echo "          Each host manages its own rails independently"
    echo ""
    echo "Command:"
    echo "  export NCCL_MNNVL_ENABLE=2"
    echo "  export NCCL_MNNVL_RAIL_PER_HOST=1"
    echo "  export NCCL_DEBUG=INFO"
    echo "  export NCCL_DEBUG_SUBSYS=INIT,GRAPH,NET"
    echo "  mpirun -np 32 -hosts node1,node2,node3,node4 ./your_nccl_application"
    echo ""
}

# Example 3: Forced MNNVL with specific clique ID
example_3_forced_mnnvl() {
    print_section "Example 3: Forced MNNVL with Specific Clique"
    
    echo "Configuration:"
    echo "  - NCCL_MNNVL_ENABLE=1 (forced)"
    echo "  - NCCL_MNNVL_CLIQUE_ID=100"
    echo "  - NCCL_MNNVL_RAIL_PER_HOST=1"
    echo ""
    echo "Use case: Testing or explicit configuration for specific hardware"
    echo ""
    echo "Command:"
    echo "  export NCCL_MNNVL_ENABLE=1"
    echo "  export NCCL_MNNVL_CLIQUE_ID=100"
    echo "  export NCCL_MNNVL_RAIL_PER_HOST=1"
    echo "  export NCCL_DEBUG=INFO"
    echo "  mpirun -np 64 ./your_nccl_application"
    echo ""
}

# Example 4: Full debug mode for topology analysis
example_4_debug_topology() {
    print_section "Example 4: Debug Topology and Rail Selection"
    
    echo "Configuration:"
    echo "  - NCCL_MNNVL_ENABLE=2"
    echo "  - NCCL_MNNVL_RAIL_PER_HOST=1"
    echo "  - Full debug output"
    echo ""
    echo "Use case: Analyzing topology detection and path selection"
    echo ""
    echo "Command:"
    echo "  export NCCL_MNNVL_ENABLE=2"
    echo "  export NCCL_MNNVL_RAIL_PER_HOST=1"
    echo "  export NCCL_DEBUG=INFO"
    echo "  export NCCL_DEBUG_SUBSYS=INIT,GRAPH,NET,COLL"
    echo "  export NCCL_DEBUG_FILE=/tmp/nccl_debug_%h_%p.log"
    echo "  mpirun -np 16 ./your_nccl_application"
    echo ""
    echo "This will create detailed logs showing:"
    echo "  - Detected topology (GPU, NIC, interconnects)"
    echo "  - Path selection decisions (PATH_NVL, PATH_PXN, etc.)"
    echo "  - Rail assignments and crossNic mode"
    echo "  - Channel allocations"
    echo ""
}

# Example 5: Verifying MNNVL detection
example_5_verify() {
    print_section "Example 5: Verify MNNVL is Active"
    
    echo "To verify that MNNVL is being used:"
    echo ""
    echo "1. Enable debug logging:"
    echo "   export NCCL_DEBUG=INFO"
    echo "   export NCCL_DEBUG_SUBSYS=INIT"
    echo ""
    echo "2. Look for these messages in the output:"
    echo "   - 'MNNVL busId 0x... fabric UUID ... cliqueId ...'"
    echo "   - 'comm ... MNNVL 1' (indicates MNNVL is enabled)"
    echo "   - 'NVLink domains: N domains' (where N > 1 for multi-node)"
    echo ""
    echo "3. Check for PATH_PXN in topology:"
    echo "   export NCCL_DEBUG_SUBSYS=INIT,GRAPH"
    echo "   Look for 'PATH_PXN' in the path selection output"
    echo ""
}

# Example 6: Environment variable reference
example_6_env_reference() {
    print_section "Example 6: Environment Variable Reference"
    
    echo "MNNVL Configuration:"
    echo "  NCCL_MNNVL_ENABLE"
    echo "    0 = Disabled"
    echo "    1 = Force enable"
    echo "    2 = Auto-detect (default)"
    echo ""
    echo "  NCCL_MNNVL_UUID"
    echo "    Sets fabric UUID for identification"
    echo ""
    echo "  NCCL_MNNVL_CLIQUE_ID"
    echo "    -2 = Auto-detect from hardware"
    echo "    -1 = No specific clique ID"
    echo "    N  = Explicit clique ID"
    echo ""
    echo "  NCCL_MNNVL_RAIL_PER_HOST"
    echo "    0 = Rails identified globally (default)"
    echo "    1 = Rails identified per-host"
    echo ""
    echo "Debug Configuration:"
    echo "  NCCL_DEBUG"
    echo "    VERSION = Version info only"
    echo "    WARN    = Warnings"
    echo "    INFO    = Informational messages"
    echo "    TRACE   = Detailed trace"
    echo ""
    echo "  NCCL_DEBUG_SUBSYS"
    echo "    INIT  = Initialization"
    echo "    GRAPH = Topology and graph algorithms"
    echo "    NET   = Network operations"
    echo "    COLL  = Collective operations"
    echo "    ALL   = All subsystems"
    echo ""
}

# Run all examples
example_1_basic_mnnvl
example_2_rail_per_host
example_3_forced_mnnvl
example_4_debug_topology
example_5_verify
example_6_env_reference

# Summary
print_section "Summary"
echo "This script demonstrates various configurations for NCCL's"
echo "Multi-Node NVLink (MNNVL) and Rail Optimization features."
echo ""
echo "Key Points:"
echo "  1. MNNVL enables cross-machine topology awareness"
echo "  2. Rail optimization balances traffic across multiple NICs"
echo "  3. PATH_PXN enables rail-local aggregated network operations"
echo "  4. Use NCCL_DEBUG to verify feature activation"
echo ""
echo "For more information, see:"
echo "  - MNNVL_AND_RAIL_OPTIMIZATION.md (English)"
echo "  - MNNVL_AND_RAIL_OPTIMIZATION_CN.md (Chinese)"
echo ""
echo "Official documentation:"
echo "  https://docs.nvidia.com/deeplearning/nccl/"
echo ""
echo "=================================================="
