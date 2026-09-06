---
id: source-microsoft-windows-acceptex-provider
title: Microsoft AcceptEx setup and Winsock provider ownership
kind: source
status: captured
summary: Pinned AcceptEx setup and socket-provider contracts separate fixed application ownership from operating-system resources and terminal completion.
captured: 2026-09-06
revision: 5f2625b6782d3e9c0df08756583c527a0a2872ca
url: https://github.com/MicrosoftDocs/sdk-api/blob/5f2625b6782d3e9c0df08756583c527a0a2872ca/sdk-api-src/content/mswsock/nf-mswsock-acceptex.md
snapshot: sources/snapshots/microsoft-windows-acceptex-provider.json
sha256: "cf609ab7dc4520216b4ab6001f54878a03a79a1bb223a1e6fc94ed324e45f896"
---

# Microsoft AcceptEx setup and Winsock provider ownership

MicrosoftDocs/sdk-api commit `5f2625b6782d3e9c0df08756583c527a0a2872ca` resolves to tree `dfde8fe2c7e0b9aca036b727aa7b433c6352f4d5`.
The curator independently checked the commit, five remote Git blobs, and their SHA-256 digests on 2026-09-06.
The snapshot retains full file paths, blob identities, digests, retrieval time, and pinned URLs.
Earlier Microsoft source records remain unchanged.

A Winsock provider implements socket services and owns associated operating-system resources.
`AcceptEx` starts an overlapped accept into a socket that the application already created.
These contracts describe public Windows APIs, rather than a `std.Io` implementation.

All paths below start at `sdk-api-src/content/` in the pinned tree.

| Primary file | Supported contract |
| --- | --- |
| `mswsock/nf-mswsock-acceptex.md` | A zero receive length completes after connection arrival without waiting for request data. Each address region requires the transport address size plus 16 bytes. IPv4 therefore needs at least 32 bytes per region. |
| `mswsock/nf-mswsock-acceptex.md` | The application resolves `AcceptEx` through `WSAIoctl` with `SIO_GET_EXTENSION_FUNCTION_POINTER` and `WSAID_ACCEPTEX`. The accepted socket needs `SO_UPDATE_ACCEPT_CONTEXT` before ordinary configuration. |
| `winsock2/nf-winsock2-wsasocketw.md` | `WSASocketW` allocates a descriptor and related provider resources. `WSA_FLAG_OVERLAPPED` enables overlapped operations; `WSA_FLAG_NO_HANDLE_INHERIT` prevents handle inheritance. |
| `winsock/nf-winsock-setsockopt.md` | `SO_EXCLUSIVEADDRUSE` requests exclusive binding. `SO_UPDATE_ACCEPT_CONTEXT` associates the accepted socket with the listener's context. |
| `winsock2/nf-winsock2-wsaioctl.md` | Provider behavior can make an IOCTL block indefinitely. API availability alone supplies no bounded completion-time guarantee. |
| `winsock/nf-winsock-closesocket.md` | A released descriptor can be reused immediately. Pending overlapped operations still require their terminal notifications before referenced storage can be reclaimed. |
| `winsock/nf-winsock-closesocket.md` | Default graceful close can return while the provider retains socket resources during background cleanup. The application cannot infer a kernel-resource bound from its handle table. |

The focused `AcceptEx` anchors are lines 72–85, 118–120, and 200–213.
The socket-creation anchors are lines 440–447, 557–564, and 763–783.
The close-ownership anchors are lines 146–155 and 177–222.
The actual close and option records use the `winsock/` directory.
These explicit paths supersede any shorthand path grouping in earlier source inventories.

## Exact Zig ABI boundary

The snapshot also pins four files from Zig release commit `44d9672fed001115e674fd5ddb32747ef43a7af4`.
All four copied files match the installed Zig 0.16.0 release byte for byte.

- `lib/libc/include/any-windows-any/mswsock.h`
- `lib/libc/include/any-windows-any/winsock2.h`
- `lib/libc/include/any-windows-any/psdk_inc/_wsadata.h`
- `lib/std/os/windows/ws2_32.zig`

These files support ABI declarations and constants used by the custom HTTP adapter.
They do not supply a standard-library IOCP backend or establish Windows runtime behavior.
[[zig-0.16-windows-io-source]] retains the separate `std.Io.Threaded` mapping.
[[microsoft-windows-iocp-api]] supplies completion-notification and cancellation contracts.
[[microsoft-windows-winsock-batched-file-io]] supplies payload ownership and batched-result contracts.

Synthesis: [[windows-iocp-and-overlapped-io]], [[bounded-http-server-design]], and [[platform-io-backend-decision-table]].
