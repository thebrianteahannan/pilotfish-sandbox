package com.pilotfish.swingdemo.driver;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * Writes a step timeline after each action so a later video/TTS mux can align narration.
 */
public final class Timeline {

    public static final class Entry {
        public String id;
        public String action;
        public String detail;
        public long startedAtMs;
        public long endedAtMs;
        public int dwellMs;
        public boolean skipped;
    }

    private final Path path;
    private final String name;
    private final long sessionStart = System.currentTimeMillis();
    private final List<Entry> entries = new ArrayList<>();

    public Timeline(Path path, String name) {
        this.path = path;
        this.name = name == null ? "demo" : name;
    }

    public long elapsedMs() {
        return System.currentTimeMillis() - sessionStart;
    }

    public void add(Script.Step step, long startedAtMs, long endedAtMs, boolean skipped) {
        Entry entry = new Entry();
        entry.id = step.id;
        entry.action = step.action;
        entry.detail = step.detail;
        entry.startedAtMs = startedAtMs;
        entry.endedAtMs = endedAtMs;
        entry.dwellMs = step.dwellMs;
        entry.skipped = skipped;
        entries.add(entry);
        flush();
    }

    public void flush() {
        try {
            Path parent = path.toAbsolutePath().getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }
            Files.writeString(path, toJson(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot write timeline " + path, e);
        }
    }

    private String toJson() {
        StringBuilder sb = new StringBuilder();
        sb.append("{\n");
        sb.append("  \"name\": ").append(quote(name)).append(",\n");
        sb.append("  \"session_start_epoch_ms\": ").append(sessionStart).append(",\n");
        sb.append("  \"steps\": [\n");
        for (int i = 0; i < entries.size(); i++) {
            Entry e = entries.get(i);
            sb.append("    {\n");
            sb.append("      \"id\": ").append(quote(e.id)).append(",\n");
            sb.append("      \"action\": ").append(quote(e.action)).append(",\n");
            sb.append("      \"detail\": ").append(quote(e.detail)).append(",\n");
            sb.append("      \"started_at_ms\": ").append(e.startedAtMs).append(",\n");
            sb.append("      \"ended_at_ms\": ").append(e.endedAtMs).append(",\n");
            sb.append("      \"dwell_ms\": ").append(e.dwellMs).append(",\n");
            sb.append("      \"skipped\": ").append(e.skipped ? "true" : "false").append('\n');
            sb.append(i == entries.size() - 1 ? "    }\n" : "    },\n");
        }
        sb.append("  ]\n");
        sb.append("}\n");
        return sb.toString();
    }

    private static String quote(String value) {
        if (value == null) {
            return "\"\"";
        }
        String escaped = value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
        return "\"" + escaped + "\"";
    }
}
