# NCCL 多节点 NVLink (MNNVL) 和网络通道优化

## 概述

NCCL 包含了先进的跨机器拓扑感知和网络通道（Rail）优化功能，以在多节点 GPU 集群中实现最佳性能。

## 跨机器拓扑感知 (MNNVL)

### 什么是 MNNVL？

多节点 NVLink (MNNVL) 是一项功能，使 NCCL 能够理解和优化通过 NVLink 连接的多台物理机器之间的通信模式。这提供了：

- **跨机器拓扑检测**：自动发现不同节点上 GPU 之间的 NVLink 连接
- **智能路径选择**：考虑节点间 NVLink 拓扑选择最优通信路径
- **多节点 NVLink 支持**：利用机器之间的高带宽 NVLink 连接

### 配置参数

#### NCCL_MNNVL_ENABLE

控制是否启用多节点 NVLink 支持。

```bash
export NCCL_MNNVL_ENABLE=<值>
```

取值：
- `0`：禁用
- `1`：强制启用 MNNVL
- `2`：自动检测（默认）- 当检测到多个节点且 P2P 可用时启用 MNNVL

#### NCCL_MNNVL_UUID

设置 MNNVL 识别的 fabric UUID。

```bash
export NCCL_MNNVL_UUID=<值>
```

#### NCCL_MNNVL_CLIQUE_ID

设置 MNNVL fabric 分区的 clique ID。

```bash
export NCCL_MNNVL_CLIQUE_ID=<值>
```

取值：
- `-2`：从硬件自动检测（读取机架序列号、插槽、托盘信息）
- `-1`：无特定 clique ID
- 其他值：显式 clique ID

### 拓扑路径类型

NCCL 定义了多种路径类型用于不同的连接场景：

#### PATH_NVL (1)
通过 GPU 之间的 NVLink 连接。

#### PATH_NVB (2)
通过中间 GPU 的 NVLink 连接。

#### PATH_C2C (3)
通过芯片到芯片 (Chip-to-Chip) 链路的连接。

#### PATH_PXN (7)
**Rail 本地聚合网络操作**：使用中间 GPU 在 GPU 和 NIC 之间的连接。此路径类型专门设计用于启用 Rail 本地、聚合的网络发送/接收操作，以实现最佳带宽利用。

#### PATH_PHB (8)
穿过 PCIe 以及 PCIe 主桥（通常是 CPU）的连接。

#### PATH_SYS (9)
穿过 PCIe 以及 NUMA 节点之间的 SMP 互连（例如 QPI/UPI）的连接。

#### PATH_NET (10)
通过网络的连接。

## Rail 优化

### 什么是 Rail 优化？

Rail 优化确保网络流量在多个网络接口（Rails）之间得到最优分配，同时最小化跨 Rail 通信。这改善了：

- **带宽利用率**：更好地使用可用网络链路
- **延迟降低**：避免不必要的跨 Rail 跳转
- **可扩展性**：在每个节点有多个 NIC 时获得更好的性能

### 配置参数

#### NCCL_MNNVL_RAIL_PER_HOST

控制在 MNNVL 系统中是否按主机识别 Rails。

```bash
export NCCL_MNNVL_RAIL_PER_HOST=<值>
```

取值：
- `0`：禁用（默认）- Rails 通过 ASIC 和端口全局识别
- `1`：启用 - 在具有不同主机的 MNNVL 系统中，使用 PCI ID 和端口按主机识别 Rails

启用时，此参数确保在多主机 MNNVL 部署中：
- 每个主机的 Rails 被独立处理
- 不同主机上的网络接口如果具有匹配的 PCI ID 和端口，可以使用相同的 Rail 标识符
- 改善跨机器通信的路径选择

### 跨 NIC 通信

NCCL 自动检测并优化具有多个网络接口的系统：

#### crossNic 模式

- **crossNic = 0**：所有通道使用相同的 NIC（相同的 ASIC/端口）
- **crossNic = 1**：通道可能使用不同的 NIC
- **crossNic = 2**：通道有意在 NIC 之间交替以平衡负载

#### Ring 交替

对于 `crossNic = 2` 的系统，NCCL 交替 Ring 分配以避免跨 Rail：

- 通道成对（偶数/奇数）
- 奇数节点交换它们的 Ring 分配
- 这确保了跨 Rails 的流量分布平衡

双 Rail 网络系统的示例配置：
```bash
# 启用 MNNVL 并按主机使用 Rail
export NCCL_MNNVL_ENABLE=2
export NCCL_MNNVL_RAIL_PER_HOST=1

# 让 NCCL 自动检测最优 crossNic 策略
# 系统将在有益时自动使用 crossNic=2
```

## 实现细节

### 拓扑检测 (src/graph/topo.h, topo.cc)

拓扑系统维护：
- 节点类型：GPU、PCI、NVS (NVSwitch)、CPU (NUMA)、NIC、NET
- 不同连接技术的链路类型和带宽
- 所有节点之间的预计算路径
- 系统范围和每个节点的拓扑信息

### 路径选择 (src/graph/paths.cc)

路径选择算法：
1. 计算源和目标之间的所有可能路径
2. 考虑带宽、延迟和路径类型
3. 对于 PATH_PXN 路径，识别用于聚合的中间 GPU
4. 根据通信模式选择最优路径

### 网络搜索 (src/graph/search.cc)

搜索算法：
1. 根据 Rail 配置检查网络接口兼容性
2. 为跨主机场景应用 MNNVL_RAIL_PER_HOST 规则
3. 验证路径类型是否符合允许的最大类型
4. 确保通道组内一致的 Rail 使用

### 连接设置 (src/graph/connect.cc)

连接设置：
1. 分配通信通道
2. 为 crossNic = 2 系统应用 Ring 交替
3. 交换 Ring 分配以实现负载均衡
4. 建立优化的通信路径

## 使用示例

### 示例 1：基本 MNNVL 设置

对于具有节点间 NVLink 连接的系统：

```bash
# 启用 MNNVL 自动检测
export NCCL_MNNVL_ENABLE=2

# 运行您的应用程序
mpirun -np 16 ./your_nccl_application
```

### 示例 2：多 Rail 配置

对于每个节点有多个 NIC 的系统：

```bash
# 启用 MNNVL
export NCCL_MNNVL_ENABLE=2

# 启用按主机的 Rail 识别
export NCCL_MNNVL_RAIL_PER_HOST=1

# 可选：启用调试输出以查看拓扑决策
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=GRAPH,NET

# 运行您的应用程序
mpirun -np 32 ./your_nccl_application
```

### 示例 3：强制特定拓扑

用于测试或特定硬件配置：

```bash
# 强制启用 MNNVL
export NCCL_MNNVL_ENABLE=1

# 设置特定 clique ID
export NCCL_MNNVL_CLIQUE_ID=100

# 启用按主机的 Rail
export NCCL_MNNVL_RAIL_PER_HOST=1

# 运行您的应用程序
mpirun -np 64 ./your_nccl_application
```

## 性能考虑

### 何时使用 MNNVL

MNNVL 在以下情况下提供好处：
- 多个节点通过 NVLink 连接（例如 GB200-NVL72 系统）
- 需要高带宽的节点间通信
- 工作负载受益于跨节点的直接 GPU 到 GPU 通信

### 何时使用 Rail 优化

Rail 优化在以下情况下有益：
- 每个节点有多个 NIC
- 网络带宽是瓶颈
- 平衡的流量分布提高性能
- 系统具有异构网络拓扑

### 调试

要调试拓扑和 Rail 选择：

```bash
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,GRAPH,NET,COLL

# 这将显示：
# - 检测到的拓扑
# - 路径选择决策
# - Rail 分配
# - 通道分配
```

## 硬件支持

### 支持的架构

- NVIDIA Pascal (P100) - SM 6.0
- NVIDIA Volta (V100) - SM 7.0
- NVIDIA Ampere (A100, A30) - SM 8.0, 8.6
- NVIDIA Ada (RTX 40 系列) - SM 8.9
- NVIDIA Hopper (H100, H200) - SM 9.0
- NVIDIA Blackwell (B100, B200, GB200) - SM 10.0

### 按代的 NVLink 带宽

- Pascal (SM 6.0): 每条链路 18.0 GB/s
- Volta (SM 7.0): 每条链路 20.0 GB/s
- Ampere (SM 8.0): 每条链路 20.0 GB/s
- Ampere (SM 8.6): 每条链路 12.0 GB/s
- Hopper (SM 9.0): 每条链路 20.6 GB/s
- Blackwell (SM 10.0): 每条链路 40.1 GB/s

## 参考

- 源文件：
  - `src/graph/topo.h` - 拓扑定义和结构
  - `src/graph/topo.cc` - 拓扑构建和管理
  - `src/graph/paths.cc` - 路径计算和选择
  - `src/graph/search.cc` - 网络搜索和 Rail 优化
  - `src/graph/connect.cc` - 连接设置和 Ring 交替
  - `src/init.cc` - MNNVL 初始化和配置

- 代码中的关键参数：
  - `src/graph/search.cc` 第 557 行：`NCCL_PARAM(MnnvlRailPerHost, "MNNVL_RAIL_PER_HOST", 0)`
  - `src/init.cc` 第 740 行：`NCCL_PARAM(MNNVLEnable, "MNNVL_ENABLE", 2)`
  - `src/graph/topo.h` 第 83 行：`#define PATH_PXN 7` - Rail 本地聚合操作

有关更多信息，请参阅 NCCL 文档：https://docs.nvidia.com/deeplearning/nccl/
