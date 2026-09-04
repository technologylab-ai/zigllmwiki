#include <dispatch/dispatch.h>

#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

struct zigllm_dispatch_io_channel {
    dispatch_queue_t callback_queue;
    dispatch_io_t io;
};

struct zigllm_dispatch_io_read {
    void *buffer;
    size_t capacity;
    size_t copied;
    int error_code;
    dispatch_semaphore_t complete;
};

struct zigllm_dispatch_io_channel *zigllm_dispatch_io_open_random(
    const char *absolute_path
) {
    struct zigllm_dispatch_io_channel *channel = calloc(1, sizeof(*channel));
    if (channel == NULL) return NULL;

    channel->callback_queue = dispatch_queue_create(
        "org.technologylab.zigllmwiki.dispatch-io-proof",
        DISPATCH_QUEUE_SERIAL
    );
    if (channel->callback_queue == NULL) {
        free(channel);
        return NULL;
    }

    channel->io = dispatch_io_create_with_path(
        DISPATCH_IO_RANDOM,
        absolute_path,
        O_RDONLY | O_CLOEXEC,
        0,
        channel->callback_queue,
        ^(int error_code) {
            (void)error_code;
        }
    );
    if (channel->io == NULL) {
        dispatch_release(channel->callback_queue);
        free(channel);
        return NULL;
    }

    return channel;
}

int zigllm_dispatch_io_read(
    struct zigllm_dispatch_io_channel *channel,
    int64_t offset,
    void *buffer,
    size_t length,
    size_t *bytes_read
) {
    __block struct zigllm_dispatch_io_read operation = {
        .buffer = buffer,
        .capacity = length,
        .copied = 0,
        .error_code = 0,
        .complete = dispatch_semaphore_create(0),
    };
    if (operation.complete == NULL) return ENOMEM;

    dispatch_io_read(
        channel->io,
        offset,
        length,
        channel->callback_queue,
        ^(bool done, dispatch_data_t data, int error_code) {
            if (error_code != 0 && operation.error_code == 0) {
                operation.error_code = error_code;
            }

            if (data != NULL && operation.error_code == 0) {
                dispatch_data_apply(
                    data,
                    ^bool(
                        dispatch_data_t region,
                        size_t region_offset,
                        const void *bytes,
                        size_t size
                    ) {
                        (void)region;
                        (void)region_offset;
                        if (size > operation.capacity - operation.copied) {
                            operation.error_code = EMSGSIZE;
                            return false;
                        }
                        memcpy(
                            (unsigned char *)operation.buffer + operation.copied,
                            bytes,
                            size
                        );
                        operation.copied += size;
                        return true;
                    }
                );
            }

            if (done) {
                dispatch_semaphore_signal(operation.complete);
            }
        }
    );

    dispatch_semaphore_wait(operation.complete, DISPATCH_TIME_FOREVER);
    dispatch_release(operation.complete);
    *bytes_read = operation.copied;
    return operation.error_code;
}

void zigllm_dispatch_io_close(struct zigllm_dispatch_io_channel *channel) {
    dispatch_io_close(channel->io, 0);
    dispatch_release(channel->io);
    dispatch_release(channel->callback_queue);
    free(channel);
}
