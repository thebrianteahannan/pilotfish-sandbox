package com.pilotfish.swingdemo.driver;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;

import com.pilotfish.swingdemo.agent.AgentClient;
import com.pilotfish.swingdemo.agent.EiConsoleAttach;

/**
 * Attach to a live eiConsole JVM and play a YAML click-through script.
 */
public final class Main {

    private static final Path DEFAULT_AGENT_JAR = Path.of(
            "target", "swing-demo-auto-0.1.0-SNAPSHOT-agent.jar");

    public static void main(String[] args) throws Exception {
        Path scriptPath = null;
        Path timelinePath = Path.of("out", "timeline.json");
        Path dumpPath = null;
        Path eipRoot = null;
        Path agentJar = DEFAULT_AGENT_JAR;
        boolean relaunch = true;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--app" -> requireValue(args, ++i, "--app");
                case "--script" -> scriptPath = Path.of(requireValue(args, ++i, "--script"));
                case "--timeline" -> timelinePath = Path.of(requireValue(args, ++i, "--timeline"));
                case "--dump" -> dumpPath = Path.of(requireValue(args, ++i, "--dump"));
                case "--eip-root" -> eipRoot = Path.of(requireValue(args, ++i, "--eip-root"));
                case "--agent-jar" -> agentJar = Path.of(requireValue(args, ++i, "--agent-jar"));
                case "--no-relaunch" -> relaunch = false;
                default -> throw new IllegalArgumentException("Unknown argument: " + args[i] + "\n" + usage());
            }
        }
        if (scriptPath == null && dumpPath == null) {
            throw new IllegalArgumentException("Need --script and/or --dump\n" + usage());
        }
        Path portFile = Path.of("out", "agent.port");
        Files.createDirectories(Path.of("out"));
        try (AgentClient agent = EiConsoleAttach.connect(
                agentJar.toAbsolutePath(),
                portFile.toAbsolutePath(),
                eipRoot,
                Duration.ofSeconds(90),
                relaunch)) {
            if (dumpPath != null && scriptPath == null) {
                agent.dump(dumpPath.toAbsolutePath());
                System.out.println("Wrote component dump to " + dumpPath.toAbsolutePath());
            }
            if (scriptPath != null) {
                Script script = Script.load(scriptPath);
                Timeline timeline = new Timeline(timelinePath, script.name);
                try {
                    agent.front();
                    DemoPlayer.play(
                            script,
                            (target, optional) -> {
                                agent.front();
                                return agent.find(target, optional ? 2_000 : 8_000);
                            },
                            new RobotGestures(),
                            timeline);
                } finally {
                    timeline.flush();
                }
            }
            if (dumpPath != null && scriptPath != null) {
                agent.dump(dumpPath.toAbsolutePath());
                System.out.println("Wrote component dump to " + dumpPath.toAbsolutePath());
            }
        }
    }

    private static String requireValue(String[] args, int index, String flag) {
        if (index >= args.length) {
            throw new IllegalArgumentException(flag + " needs a value\n" + usage());
        }
        return args[index];
    }

    private static String usage() {
        return """
                Usage:
                  --eip-root <eip-root> --script <walkthrough.yaml> [--timeline out/timeline.json]
                  --eip-root <eip-root> --dump out/eiconsole-tree.txt
                """;
    }
}
