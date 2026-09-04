---
id: source-linux-io-uring-uapi-history
title: Linux io_uring UAPI release history
kind: source
status: captured
summary: Pinned Linux release-tag evidence for the io_uring ABI features that constrain Zig 0.16 backends.
captured: 2026-09-04
revision: "Linux release tags v5.1 through v7.1; exact commits in body"
url: https://github.com/torvalds/linux/blob/8cd9520d35a6c38db6567e97dd93b1f11f185dc6/include/uapi/linux/io_uring.h
---

# Linux `io_uring` UAPI release history

This record compares `include/uapi/linux/io_uring.h` at immutable Linux release
commits. It is used to establish a lower bound for when an ABI name first
appears in a released UAPI, not to claim that every operation works for every
file type, filesystem, device, security policy, or distribution kernel.
Runtime code must still inspect `io_uring_params.features`, use
`IORING_REGISTER_PROBE` for opcodes, handle setup failure, and test the actual
workload.

| Tag | Commit |
| --- | --- |
| `v5.1` | `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd` |
| `v5.4` | `219d54332a09e8d8741c1e1982f5eae56099de85` |
| `v5.5` | `d5226fa6dbae0569ee43ecfc08bdcd6770fc4755` |
| `v5.6` | `7111951b8d4973bda27ff663f2cf18b663d15b48` |
| `v5.7` | `3d77e6a8804abcc0504c904bd6e5cdf3a5cf8162` |
| `v5.10` | `2c85ebc57b3e1817b6ce1a6b703928e113a90442` |
| `v5.11` | `f40ddce88593482919761f74910f42f4b84c004b` |
| `v5.13` | `62fb9874f5da54fdb243003b386128037319b219` |
| `v5.17` | `f443e374ae131c168a065ea1748feac6b2e76613` |
| `v5.18` | `4b0986a3613c92f4ec1bdc7f60ec66fea135991f` |
| `v5.19` | `3d7cb6b04c3f3115719235cc6866b10326de34cd` |
| `v6.0` | `4fe89d07dcc2804c8b562f6c7896a45643d34b2f` |
| `v7.1` | `8cd9520d35a6c38db6567e97dd93b1f11f185dc6` |

The comparison tracks the base rings and fixed resources in 5.1;
`IORING_FEAT_SINGLE_MMAP` in 5.4; `IORING_OP_ASYNC_CANCEL` in 5.5;
`IORING_REGISTER_PROBE` in 5.6; `IORING_FEAT_FAST_POLL` in 5.7;
`IORING_SETUP_R_DISABLED` in 5.10; `IORING_ENTER_EXT_ARG` in 5.11;
resource tags and `IORING_CQE_F_MORE` in 5.13; CQE-skip-success in 5.17;
message-ring operations in 5.18; cooperative task running, provided-buffer
rings, and multishot accept in 5.19; and single-issuer setup plus fixed-file
cancellation matching in 6.0.

Relevant pages: [[io-uring]], [[evented-io-backends]], and [[cancellation]].
