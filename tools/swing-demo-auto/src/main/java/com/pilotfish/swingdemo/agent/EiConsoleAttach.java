package com.pilotfish.swingdemo.agent;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

import com.sun.tools.attach.VirtualMachine;

/**
 * Launch eiConsole if needed, then load our agent into that JVM.
 * Override install with env {@code EICONSOLE_HOME} (folder that contains eiConsole.app).
 */
public final class EiConsoleAttach {

    public static final Path HOME = resolveHome();
    public static final Path APP = HOME.resolve("eiConsole.app");
    private static final Path JCMD = HOME.resolve(
            ".install4j/jre.bundle/Contents/Home/bin/jcmd");

    static Path resolveHome() {
        String env = System.getenv("EICONSOLE_HOME");
        if (env != null && !env.isBlank()) {
            return Path.of(env.trim());
        }
        return Path.of("/Applications/eiConsole");
    }

    private EiConsoleAttach() {
    }

    public static AgentClient connect(
            Path agentJar,
            Path portFile,
            Path eipRoot,
            Duration launchTimeout) {
        return connect(agentJar, portFile, eipRoot, launchTimeout, true);
    }

    public static AgentClient connect(
            Path agentJar,
            Path portFile,
            Path eipRoot,
            Duration launchTimeout,
            boolean relaunch) {
        if (!APP.toFile().isDirectory()) {
            throw new IllegalStateException("eiConsole is not installed at " + APP
                    + " (EICONSOLE_HOME=" + HOME + ")");
        }
        System.out.println("eiConsole home -> " + HOME);
        if (!Files.isRegularFile(agentJar)) {
            throw new IllegalStateException("Agent jar missing. Run ./mvnw -q package — looked for " + agentJar);
        }
        if (eipRoot != null) {
            setWorkingDirectory(eipRoot);
            if (relaunch && findPid() > 0) {
                quit();
            }
        }
        boolean launched = false;
        int pid = findPid();
        if (pid <= 0) {
            launch();
            launched = true;
            pid = waitForPid(launchTimeout);
        }
        activate();
        if (launched) {
            sleep(4000);
        }
        AgentClient existing = tryExisting(portFile);
        if (existing != null) {
            existing.front();
            return existing;
        }
        attach(pid, agentJar, portFile);
        int port = waitForPort(portFile, Duration.ofSeconds(20));
        AgentClient client = new AgentClient(port);
        client.ping();
        holdSplash(client, Duration.ofSeconds(20), 2800);
        waitForMainWindow(client, Duration.ofSeconds(75));
        client.front();
        return client;
    }

    /** Keep the 26R1 splash on screen long enough to read, then let File Management take over. */
    static void holdSplash(AgentClient client, Duration timeout, long holdMs) {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        boolean seen = false;
        while (System.currentTimeMillis() < deadline) {
            try {
                String titles = client.windows();
                String lower = titles.toLowerCase(Locale.ROOT);
                if (lower.contains("splash")) {
                    seen = true;
                    break;
                }
                if (titles.contains("File Management")
                        || titles.contains("Route")
                        || titles.contains("Interface")) {
                    break;
                }
            } catch (Exception ignored) {
                // agent still coming up
            }
            sleep(200);
        }
        if (seen) {
            System.out.println("Holding eiConsole splash for " + holdMs + "ms");
            sleep(holdMs);
        }
    }

    static void waitForMainWindow(AgentClient client, Duration timeout) {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            try {
                String titles = client.windows();
                String lower = titles.toLowerCase(Locale.ROOT);
                if (!titles.isBlank()
                        && !lower.contains("splash")
                        && (titles.contains("Route File Management")
                        || titles.contains("File Management")
                        || titles.contains("Interface Overview"))) {
                    return;
                }
            } catch (Exception ignored) {
                // agent still coming up
            }
            sleep(400);
        }
        throw new IllegalStateException("eiConsole main window did not appear");
    }

    static void setWorkingDirectory(Path eipRoot) {
        if (!Files.isDirectory(eipRoot) || !Files.isDirectory(eipRoot.resolve("interfaces"))) {
            throw new IllegalArgumentException("Not an eip-root with interfaces/: " + eipRoot);
        }
        String path = eipRoot.toAbsolutePath().toString();
        try {
            java.util.prefs.Preferences prefs = java.util.prefs.Preferences.userRoot()
                    .node("com/pilotfish/eip/gui/console/config/prefs");
            prefs.put("com.pilotfish.eip.console.workingDirectory", path);
            prefs.put("com.pilotfish.eip.console.workingDirectory_0", path);
            prefs.flush();
        } catch (Exception e) {
            throw new IllegalStateException("Cannot set eiConsole working directory", e);
        }
        System.out.println("eiConsole working directory -> " + path);
    }

    static AgentClient tryExisting(Path portFile) {
        try {
            if (!Files.isRegularFile(portFile)) {
                return null;
            }
            int port = Integer.parseInt(Files.readString(portFile).strip());
            AgentClient client = new AgentClient(port);
            client.ping();
            return client;
        } catch (Exception e) {
            return null;
        }
    }

    static void quit() {
        run(List.of("osascript", "-e", "tell application \"" + APP + "\" to quit"), 15);
        run(List.of("osascript", "-e", "tell application \"eiConsole\" to quit"), 15);
        sleep(800);
        run(List.of("killall", "eiConsole"), 5);
        sleep(500);
    }

    static void launch() {
        run(List.of("open", "-a", APP.toString()), 20);
    }

    static void activate() {
        run(List.of("open", "-a", APP.toString()), 10);
    }

    static int waitForPid(Duration timeout) {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            int pid = findPid();
            if (pid > 0) {
                return pid;
            }
            sleep(400);
        }
        throw new IllegalStateException("eiConsole did not start a JVM within " + timeout);
    }

    static int findPid() {
        String out = run(List.of("pgrep", "-lf", "eiConsole"), 8);
        if (out.isBlank()) {
            out = run(List.of("ps", "-axo", "pid=,command="), 15);
        }
        int best = -1;
        for (String line : out.split("\n")) {
            String trimmed = line.strip();
            if (trimmed.isEmpty()) {
                continue;
            }
            int space = indexOfPidBreak(trimmed);
            if (space < 0) {
                continue;
            }
            int pid;
            try {
                pid = Integer.parseInt(trimmed.substring(0, space).strip());
            } catch (NumberFormatException e) {
                continue;
            }
            String cmd = trimmed.substring(space).strip().toLowerCase(Locale.ROOT);
            String appNeedle = APP.toAbsolutePath().toString().toLowerCase(Locale.ROOT);
            if (cmd.contains(appNeedle)
                    && !cmd.contains("uninstaller")
                    && !cmd.contains("datamapper")) {
                return pid;
            }
            if (best < 0 && cmd.contains("eiconsole.app/contents/macos")
                    && cmd.contains(HOME.toAbsolutePath().toString().toLowerCase(Locale.ROOT))) {
                best = pid;
            }
        }
        return best;
    }

    private static int indexOfPidBreak(String line) {
        for (int i = 0; i < line.length(); i++) {
            if (Character.isWhitespace(line.charAt(i))) {
                return i;
            }
        }
        return -1;
    }

    static void attach(int pid, Path agentJar, Path portFile) {
        try {
            Files.deleteIfExists(portFile);
        } catch (Exception ignored) {
            // will overwrite
        }
        String options = "portfile=" + portFile.toAbsolutePath();
        try {
            VirtualMachine vm = VirtualMachine.attach(String.valueOf(pid));
            try {
                vm.loadAgent(agentJar.toAbsolutePath().toString(), options);
            } finally {
                vm.detach();
            }
            return;
        } catch (Exception attachError) {
            if (Files.isRegularFile(JCMD)) {
                try {
                    run(List.of(
                            JCMD.toString(),
                            String.valueOf(pid),
                            "JVMTI.agent_load",
                            agentJar.toAbsolutePath().toString(),
                            options), 30);
                    return;
                } catch (Exception jcmdError) {
                    throw new IllegalStateException(
                            "Attach failed (" + attachError.getMessage() + ") and jcmd failed ("
                                    + jcmdError.getMessage() + ")",
                            attachError);
                }
            }
            throw new IllegalStateException(
                    "Cannot attach to eiConsole pid " + pid + ": " + attachError.getMessage(), attachError);
        }
    }

    static int waitForPort(Path portFile, Duration timeout) {
        long deadline = System.currentTimeMillis() + timeout.toMillis();
        while (System.currentTimeMillis() < deadline) {
            try {
                if (Files.isRegularFile(portFile)) {
                    String text = Files.readString(portFile).strip();
                    if (!text.isEmpty()) {
                        return Integer.parseInt(text);
                    }
                }
            } catch (Exception ignored) {
                // still writing
            }
            sleep(150);
        }
        throw new IllegalStateException("Agent did not write " + portFile);
    }

    static String run(List<String> command, int timeoutSec) {
        try {
            Process proc = new ProcessBuilder(command)
                    .redirectErrorStream(true)
                    .start();
            String output = new String(proc.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
            boolean finished = proc.waitFor(timeoutSec, TimeUnit.SECONDS);
            if (!finished) {
                proc.destroyForcibly();
                throw new IllegalStateException("Timed out: " + command);
            }
            if (proc.exitValue() != 0
                    && !command.get(0).equals("osascript")
                    && !command.get(0).equals("killall")
                    && !command.get(0).equals("pgrep")) {
                throw new IllegalStateException(command + " failed: " + output.strip());
            }
            return output;
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Command failed: " + command, e);
        }
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

}
