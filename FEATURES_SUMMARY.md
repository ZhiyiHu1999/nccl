# NCCL 机间拓扑感知和 Rail 优化

## 问题
> 最新版nccl里面有做机间拓扑感知和rail optimization吗

## 答案
**有的。** NCCL 包含这两个功能。

### 1. 机间拓扑感知: MNNVL (Multi-Node NVLink)
- 自动检测跨节点 NVLink 连接
- 启用: `export NCCL_MNNVL_ENABLE=2` (默认自动检测)
- 源码: `src/init.cc:740`

### 2. Rail 优化
- 多网卡负载均衡和路径优化 (PATH_PXN)
- 启用: `export NCCL_MNNVL_RAIL_PER_HOST=1`
- 源码: `src/graph/search.cc:557`, `src/graph/topo.h:83`

## 使用示例
```bash
export NCCL_MNNVL_ENABLE=2
export NCCL_MNNVL_RAIL_PER_HOST=1
mpirun -np 32 ./your_application
```

## 详细文档
- [MNNVL_AND_RAIL_OPTIMIZATION.md](MNNVL_AND_RAIL_OPTIMIZATION.md) - 详细英文文档
- [MNNVL_AND_RAIL_OPTIMIZATION_CN.md](MNNVL_AND_RAIL_OPTIMIZATION_CN.md) - 详细中文文档
- [examples/mnnvl_rail_optimization_example.sh](examples/mnnvl_rail_optimization_example.sh) - 配置示例脚本
