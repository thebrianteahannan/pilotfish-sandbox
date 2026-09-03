package com.pilotfish.swingdemo.driver;

import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.yaml.snakeyaml.Yaml;

/**
 * Declarative demo script loaded from YAML.
 */
public final class Script {

    public String name = "demo";
    public final List<Step> steps = new ArrayList<>();

    public static Script load(Path path) {
        try (Reader reader = Files.newBufferedReader(path)) {
            Object raw = new Yaml().load(reader);
            if (!(raw instanceof Map<?, ?> map)) {
                throw new IllegalArgumentException("Script must be a YAML mapping: " + path);
            }
            return fromMap(map);
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("Cannot read script " + path + ": " + e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    private static Script fromMap(Map<?, ?> raw) {
        Script script = new Script();
        if (raw.get("name") != null) {
            script.name = String.valueOf(raw.get("name"));
        }
        Object steps = raw.get("steps");
        if (!(steps instanceof List<?> list)) {
            throw new IllegalArgumentException("Script needs a 'steps' list");
        }
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> stepMap)) {
                throw new IllegalArgumentException("Each step must be a mapping");
            }
            script.steps.add(Step.fromMap((Map<String, Object>) stepMap));
        }
        return script;
    }

    public static final class Step {
        public String id = "";
        public String action = "pause";
        public Target target;
        public Target dest;
        public String text = "";
        public String detail = "";
        public String from = "";
        public String to = "";
        public String speak = "";
        public boolean optional = false;
        public int dwellMs = 1000;

        static Step fromMap(Map<String, Object> raw) {
            Step step = new Step();
            if (raw.get("id") != null) {
                step.id = String.valueOf(raw.get("id"));
            }
            if (raw.get("action") != null) {
                step.action = String.valueOf(raw.get("action")).trim().toLowerCase(Locale.ROOT);
            }
            if (raw.get("detail") != null) {
                step.detail = String.valueOf(raw.get("detail"));
            }
            if (raw.get("text") != null) {
                step.text = String.valueOf(raw.get("text"));
            }
            if (raw.get("from") != null) {
                step.from = String.valueOf(raw.get("from"));
            }
            if (raw.get("to") != null) {
                step.to = String.valueOf(raw.get("to"));
            }
            if (raw.get("speak") != null) {
                step.speak = String.valueOf(raw.get("speak"));
            }
            Object optional = raw.get("optional");
            if (optional instanceof Boolean b) {
                step.optional = b;
            } else if (optional != null) {
                step.optional = Boolean.parseBoolean(String.valueOf(optional));
            }
            Object dwell = raw.get("dwell_ms");
            if (dwell instanceof Number n) {
                step.dwellMs = n.intValue();
            } else if (dwell != null) {
                step.dwellMs = Integer.parseInt(String.valueOf(dwell));
            }
            Object target = raw.get("target");
            if (target instanceof Map<?, ?> t) {
                step.target = Target.fromMap(t);
            }
            Object dest = raw.get("dest");
            if (dest instanceof Map<?, ?> d) {
                step.dest = Target.fromMap(d);
            }
            return step;
        }
    }

    public static final class Target {
        public String name;
        public String text;
        public String contains;
        public String type;
        public String window;
        public Integer column;
        public Integer row;
        public String side;

        static Target fromMap(Map<?, ?> raw) {
            Target target = new Target();
            if (raw.get("name") != null) {
                target.name = String.valueOf(raw.get("name"));
            }
            if (raw.get("text") != null) {
                target.text = String.valueOf(raw.get("text"));
            }
            if (raw.get("contains") != null) {
                target.contains = String.valueOf(raw.get("contains"));
            }
            if (raw.get("type") != null) {
                target.type = String.valueOf(raw.get("type"));
            }
            if (raw.get("window") != null) {
                target.window = String.valueOf(raw.get("window"));
            }
            if (raw.get("column") instanceof Number n) {
                target.column = n.intValue();
            } else if (raw.get("column") != null) {
                target.column = Integer.parseInt(String.valueOf(raw.get("column")));
            }
            if (raw.get("row") instanceof Number n) {
                target.row = n.intValue();
            } else if (raw.get("row") != null) {
                target.row = Integer.parseInt(String.valueOf(raw.get("row")));
            }
            if (raw.get("side") != null) {
                target.side = String.valueOf(raw.get("side"));
            }
            return target;
        }

        public boolean isEmpty() {
            return blank(name) && blank(text) && blank(contains) && blank(type)
                    && column == null && row == null;
        }

        @Override
        public String toString() {
            List<String> parts = new ArrayList<>();
            if (!blank(name)) {
                parts.add("name=" + name);
            }
            if (!blank(text)) {
                parts.add("text=" + text);
            }
            if (!blank(contains)) {
                parts.add("contains=" + contains);
            }
            if (!blank(type)) {
                parts.add("type=" + type);
            }
            if (!blank(window)) {
                parts.add("window=" + window);
            }
            if (column != null) {
                parts.add("column=" + column);
            }
            if (row != null) {
                parts.add("row=" + row);
            }
            if (!blank(side)) {
                parts.add("side=" + side);
            }
            return parts.isEmpty() ? "(any)" : String.join(", ", parts);
        }

        private static boolean blank(String value) {
            return value == null || value.isBlank();
        }
    }
}
