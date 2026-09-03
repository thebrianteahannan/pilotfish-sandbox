package com.pilotfish.swingdemo.driver;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.function.BiConsumer;
import java.util.function.BiFunction;

/**
 * Plays a YAML script against any locator (in-process tree or remote agent).
 */
public final class DemoPlayer {

    private static Process speech;

    private DemoPlayer() {
    }

    public static void play(
            Script script,
            BiFunction<Script.Target, Boolean, Located> locator,
            RobotGestures gestures,
            Timeline timeline) {
        play(script, locator, gestures, timeline, null);
    }

    public static void play(
            Script script,
            BiFunction<Script.Target, Boolean, Located> locator,
            RobotGestures gestures,
            Timeline timeline,
            BiConsumer<Script.Target, Boolean> activate) {
        for (Script.Step step : script.steps) {
            String action = step.action == null || step.action.isBlank() ? "pause" : step.action;
            step.action = action;
            long started = timeline.elapsedMs();
            boolean skipped = false;
            try {
                switch (action) {
                    case "click" -> pointAndActivate(locator, gestures, activate, step, false);
                    case "double_click" -> pointAndActivate(locator, gestures, activate, step, true);
                    case "drag" -> {
                        Located from = locator.apply(step.target, step.optional);
                        if (step.dest == null) {
                            throw new IllegalArgumentException("drag needs dest: " + step.id);
                        }
                        Located to = locator.apply(step.dest, step.optional);
                        gestures.drag(from, to);
                    }
                    case "type" -> gestures.typeInto(locator.apply(step.target, step.optional), step.text);
                    case "select" -> {
                        gestures.click(locator.apply(step.target, step.optional));
                        gestures.pause(200);
                        try {
                            Script.Target item = new Script.Target();
                            item.type = "JList";
                            item.text = step.text;
                            gestures.click(locator.apply(item, step.optional));
                        } catch (RuntimeException e) {
                            gestures.typeText(step.text);
                            gestures.pressEnter();
                        }
                    }
                    case "wait_for" -> locator.apply(step.target, step.optional);
                    case "hover" -> gestures.hover(locator.apply(step.target, step.optional));
                    case "page_down" -> gestures.pageDown();
                    case "escape" -> gestures.pressEscape();
                    case "menu_item" -> appleMenu(step);
                    case "copy_file" -> copyFile(step);
                    case "shell" -> runShell(step);
                    case "pause" -> {
                        // dwell only
                    }
                    default -> throw new IllegalArgumentException("Unknown action: " + action);
                }
            } catch (RuntimeException e) {
                if (!step.optional) {
                    throw e;
                }
                skipped = true;
                System.out.printf(Locale.ROOT, "[%s] skipped: %s%n", step.id, e.getMessage());
            }
            if (skipped) {
                stopSpeech();
                dwell(Math.min(200, Math.max(step.dwellMs, 0)));
            } else {
                startSpeech(step);
                dwell(step.dwellMs);
            }
            timeline.add(step, started, timeline.elapsedMs(), skipped);
            System.out.printf(Locale.ROOT, "[%s] %s%n", step.id, step.detail);
        }
        stopSpeech();
    }

    private static void pointAndActivate(
            BiFunction<Script.Target, Boolean, Located> locator,
            RobotGestures gestures,
            BiConsumer<Script.Target, Boolean> activate,
            Script.Step step,
            boolean doubleClick) {
        Located located = locator.apply(step.target, step.optional);
        if (activate != null) {
            gestures.hover(located);
            activate.accept(step.target, doubleClick);
        } else if (doubleClick) {
            gestures.doubleClick(located);
        } else {
            gestures.click(located);
        }
    }

    private static void appleMenu(Script.Step step) {
        if (step.target == null || step.target.text == null || step.target.text.isBlank()) {
            throw new IllegalArgumentException("menu_item needs target.text: " + step.id);
        }
        String menu = step.target.contains != null && !step.target.contains.isBlank()
                ? step.target.contains
                : "File";
        String item = step.target.text.replace("\"", "");
        String window = step.target.window == null ? "" : step.target.window.replace("\"", "");
        String raise = window.isBlank()
                ? ""
                : "repeat with w in (every window whose name contains \"" + window + "\")\n"
                        + "perform action \"AXRaise\" of w\nend repeat\ndelay 0.3\n";
        String script = "tell application \"System Events\"\n"
                + "tell process \"eiConsole\"\n"
                + "set frontmost to true\n"
                + raise
                + "click menu item \"" + item + "\" of menu 1 of menu bar item \"" + menu + "\" of menu bar 1\n"
                + "end tell\nend tell";
        try {
            Process proc = new ProcessBuilder("osascript", "-e", script).redirectErrorStream(true).start();
            String out = new String(proc.getInputStream().readAllBytes());
            if (!proc.waitFor(8, java.util.concurrent.TimeUnit.SECONDS)) {
                proc.destroyForcibly();
                throw new IllegalStateException("osascript timed out for " + step.id);
            }
            if (proc.exitValue() != 0) {
                throw new IllegalStateException("osascript failed for " + step.id + ": " + out.strip());
            }
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("menu_item failed for " + step.id + ": " + e.getMessage(), e);
        }
    }

    private static void runShell(Script.Step step) {
        String cmd = step.text != null && !step.text.isBlank() ? step.text : step.from;
        if (cmd == null || cmd.isBlank()) {
            throw new IllegalArgumentException("shell needs text: " + step.id);
        }
        try {
            Process proc = new ProcessBuilder("bash", "-lc", cmd)
                    .redirectErrorStream(true)
                    .start();
            String out = new String(proc.getInputStream().readAllBytes());
            if (!proc.waitFor(30, java.util.concurrent.TimeUnit.SECONDS)) {
                proc.destroyForcibly();
                throw new IllegalStateException("shell timed out for " + step.id);
            }
            if (proc.exitValue() != 0) {
                throw new IllegalStateException("shell failed for " + step.id + ": " + out.strip());
            }
            if (!out.isBlank()) {
                System.out.printf(Locale.ROOT, "[%s] %s%n", step.id, out.strip());
            }
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("shell failed for " + step.id + ": " + e.getMessage(), e);
        }
    }

    private static void copyFile(Script.Step step) {
        if (step.from == null || step.from.isBlank() || step.to == null || step.to.isBlank()) {
            throw new IllegalArgumentException("copy_file needs from and to: " + step.id);
        }
        try {
            Path src = Path.of(step.from);
            Path dest = Path.of(step.to);
            if (dest.getParent() != null) {
                Files.createDirectories(dest.getParent());
            }
            Files.copy(src, dest, StandardCopyOption.REPLACE_EXISTING);
        } catch (Exception e) {
            throw new IllegalStateException("copy_file failed for " + step.id + ": " + e.getMessage(), e);
        }
    }

    private static void startSpeech(Script.Step step) {
        stopSpeech();
        if (step.speak == null || step.speak.isBlank()) {
            return;
        }
        Path wav = Path.of(step.speak);
        if (!Files.isRegularFile(wav)) {
            return;
        }
        try {
            speech = new ProcessBuilder("afplay", wav.toAbsolutePath().toString())
                    .redirectErrorStream(true)
                    .start();
        } catch (Exception ignored) {
            speech = null;
        }
    }

    private static void stopSpeech() {
        if (speech == null) {
            return;
        }
        speech.destroy();
        try {
            speech.waitFor(400, java.util.concurrent.TimeUnit.MILLISECONDS);
        } catch (Exception ignored) {
            // next line can start
        }
        if (speech.isAlive()) {
            speech.destroyForcibly();
        }
        speech = null;
    }

    public static void dwell(int ms) {
        if (ms <= 0) {
            return;
        }
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted during dwell", e);
        }
    }
}
