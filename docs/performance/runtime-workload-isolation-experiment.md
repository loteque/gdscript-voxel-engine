# Chunk Streamer Runtime Workload Isolation

This validation experiment isolates the runtime work surrounding `ChunkStreamer` resource loading while preserving the production request-admission, prioritization, threaded request, and status-polling path.

The experiment runs four modes at concurrency 1, three repetitions each: normal runtime, hidden geometry, no scene integration, and loader-only. The modes progressively remove rendering and post-load scene work while keeping the same manifest, waypoint traversal, cache-provenance label, and resource-loading lifecycle.

The purpose is to explain the observed gap between the isolated `ResourceLoader` benchmark and the rendered streaming runtime. Results should be interpreted comparatively. If hidden geometry improves throughput, rendering is implicated. If no scene integration improves throughput, scene construction or attachment is implicated. If only loader-only improves throughput, residency bookkeeping or validation is implicated. If no mode materially changes throughput, the bottleneck remains within the shared loading/runtime context rather than downstream scene work.

This is diagnostic infrastructure, not a production loading policy. Production behavior remains unchanged outside the validation scene.

The mobile UI uses the title **Chunk Streamer Runtime Workload Isolation**, exposes one automated 12-run action, keeps detailed telemetry collapsible, and exports one JSON evidence file after completion.
