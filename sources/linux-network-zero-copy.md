---
id: source-linux-network-zero-copy
title: Linux network copy avoidance and receive prerequisites
kind: source
status: captured
summary: Pinned kernel documentation separates socket send copy avoidance from hardware-dependent io_uring zero-copy receive.
captured: 2026-09-05
revision: "8cd9520d35a6c38db6567e97dd93b1f11f185dc6"
url: https://github.com/torvalds/linux/tree/8cd9520d35a6c38db6567e97dd93b1f11f185dc6/Documentation/networking
---

# Linux network copy avoidance

Read both complete documents at the existing Linux v7.1 source pin:

- [msg_zerocopy.rst](https://github.com/torvalds/linux/blob/8cd9520d35a6c38db6567e97dd93b1f11f185dc6/Documentation/networking/msg_zerocopy.rst)
  describes page pinning, reuse notifications, optional copied fallback and
  overhead that generally favors writes above roughly 10 KB. TCP/UDP loopback
  incurs a deferred copy. Reuse notification is not peer delivery confirmation.
- [iou-zcrx.rst](https://github.com/torvalds/linux/blob/8cd9520d35a6c38db6567e97dd93b1f11f185dc6/Documentation/networking/iou-zcrx.rst)
  describes a separate receive facility with NIC header/data split, flow
  steering, RSS, receive-memory registration and explicit buffer recycling.

Ordinary asynchronous socket receive or buffer registration alone does not
establish this receive path. These are source contracts, not evidence that
omarx1's NIC supports zero-copy receive or that exact Zig 0.16 exposes a ready
adapter. No new kernel or NIC experiment was performed. The send document
does not establish `io_uring` SEND_ZC's distinct completion protocol.
