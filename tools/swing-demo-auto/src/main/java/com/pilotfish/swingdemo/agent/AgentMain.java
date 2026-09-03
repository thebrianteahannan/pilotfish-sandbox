package com.pilotfish.swingdemo.agent;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.lang.instrument.Instrumentation;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

import javax.swing.SwingUtilities;

import com.pilotfish.swingdemo.driver.ComponentDumper;
import com.pilotfish.swingdemo.driver.ComponentFinder;
import com.pilotfish.swingdemo.driver.Located;
import com.pilotfish.swingdemo.driver.Script;

/**
 * Loaded into a live Swing JVM (eiConsole). Reports widget bounds; the host
 * process owns {@code Robot} so Accessibility stays with Terminal/Cursor.
 */
public final class AgentMain {

    public static void premain(String args, Instrumentation inst) {
        start(args);
    }

    public static void agentmain(String args, Instrumentation inst) {
        start(args);
    }

    static void start(String args) {
        Path portFile = Path.of(parsePortFile(args));
        Thread thread = new Thread(() -> serve(portFile), "swing-demo-agent");
        thread.setDaemon(true);
        thread.start();
    }

    private static String parsePortFile(String args) {
        if (args == null || args.isBlank()) {
            throw new IllegalArgumentException("Agent needs portfile=/path");
        }
        for (String part : args.split(",")) {
            String[] kv = part.split("=", 2);
            if (kv.length == 2 && "portfile".equals(kv[0].trim())) {
                return kv[1].trim();
            }
        }
        throw new IllegalArgumentException("Agent needs portfile=/path in " + args);
    }

    private static void serve(Path portFile) {
        try (ServerSocket server = new ServerSocket(0, 8, InetAddress.getByName("127.0.0.1"))) {
            Files.createDirectories(portFile.toAbsolutePath().getParent());
            Files.writeString(portFile, String.valueOf(server.getLocalPort()), StandardCharsets.UTF_8);
            while (true) {
                try (Socket socket = server.accept()) {
                    if (!handleClient(socket)) {
                        return;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static boolean handleClient(Socket socket) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
        PrintWriter out = new PrintWriter(new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);
        String line;
        while ((line = in.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) {
                continue;
            }
            try {
                if (line.equalsIgnoreCase("PING")) {
                    out.println("OK");
                } else if (line.equalsIgnoreCase("WINDOWS")) {
                    out.println("OK " + windowTitles());
                } else if (line.equalsIgnoreCase("QUIT")) {
                    out.println("OK");
                    return false;
                } else if (line.equalsIgnoreCase("FRONT")) {
                    front();
                    out.println("OK");
                } else if (line.toUpperCase(Locale.ROOT).startsWith("ACTIVATE ")) {
                    String rest = line.substring(9).trim();
                    boolean dbl = false;
                    if (rest.toLowerCase(Locale.ROOT).startsWith("double=true")) {
                        dbl = true;
                        int space = rest.indexOf(' ');
                        rest = space < 0 ? "" : rest.substring(space + 1).trim();
                    }
                    com.pilotfish.swingdemo.driver.ComponentActivator.activate(parseTarget(rest), dbl);
                    out.println("OK");
                } else if (line.toUpperCase(Locale.ROOT).startsWith("DUMP ")) {
                    ComponentDumper.writeShowing(Path.of(line.substring(5).trim()));
                    out.println("OK");
                } else if (line.toUpperCase(Locale.ROOT).startsWith("FIND ")) {
                    String rest = line.substring(5).trim();
                    long timeoutMs = 4_000;
                    if (rest.toLowerCase(Locale.ROOT).startsWith("timeout=")) {
                        int space = rest.indexOf(' ');
                        String raw = space < 0 ? rest.substring(8) : rest.substring(8, space);
                        timeoutMs = Long.parseLong(raw);
                        rest = space < 0 ? "" : rest.substring(space + 1).trim();
                    }
                    ComponentFinder finder = ComponentFinder.forShowingWindows(timeoutMs);
                    Located located = finder.locate(parseTarget(rest));
                    out.println("FOUND " + located.toWire());
                } else {
                    out.println("ERROR unknown command");
                }
            } catch (Exception e) {
                String msg = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
                out.println("ERROR " + msg.replace('\n', ' '));
            }
        }
        return true;
    }

    private static String windowTitles() throws Exception {
        final String[] holder = new String[1];
        SwingUtilities.invokeAndWait(() -> {
            StringBuilder sb = new StringBuilder();
            for (java.awt.Window window : java.awt.Window.getWindows()) {
                if (!window.isShowing()) {
                    continue;
                }
                String title = window instanceof javax.swing.JFrame frame
                        ? frame.getTitle()
                        : window.getClass().getSimpleName();
                if (sb.length() > 0) {
                    sb.append(" | ");
                }
                sb.append(title);
            }
            holder[0] = sb.toString();
        });
        return holder[0] == null ? "" : holder[0];
    }

    private static void front() throws Exception {
        SwingUtilities.invokeAndWait(() -> {
            java.awt.Window best = null;
            for (java.awt.Window window : java.awt.Window.getWindows()) {
                if (!window.isShowing()) {
                    continue;
                }
                String title = window instanceof javax.swing.JFrame frame
                        ? frame.getTitle()
                        : window.getClass().getSimpleName();
                String lower = title == null ? "" : title.toLowerCase(Locale.ROOT);
                if (lower.contains("about")) {
                    window.setVisible(false);
                    continue;
                }
                if (best == null
                        || lower.contains("file management")
                        || lower.contains("hospital")
                        || lower.contains("eiconsole")) {
                    best = window;
                }
            }
            if (best != null) {
                best.toFront();
            }
        });
    }

    static Script.Target parseTarget(String spec) {
        Script.Target target = new Script.Target();
        for (String part : tokens(spec)) {
            String[] kv = part.split("=", 2);
            if (kv.length != 2) {
                continue;
            }
            String value = kv[1];
            if (value.length() >= 2 && value.startsWith("\"") && value.endsWith("\"")) {
                value = value.substring(1, value.length() - 1);
            }
            switch (kv[0]) {
                case "name" -> target.name = value;
                case "text" -> target.text = value;
                case "contains" -> target.contains = value;
                case "type" -> target.type = value;
                case "window" -> target.window = value;
                case "column" -> target.column = Integer.parseInt(value);
                case "row" -> target.row = Integer.parseInt(value);
                case "side" -> target.side = value;
                default -> {
                }
            }
        }
        return target;
    }

    static java.util.List<String> tokens(String spec) {
        java.util.List<String> out = new java.util.ArrayList<>();
        StringBuilder cur = new StringBuilder();
        boolean inQuote = false;
        for (int i = 0; i < spec.length(); i++) {
            char ch = spec.charAt(i);
            if (ch == '"') {
                inQuote = !inQuote;
                cur.append(ch);
            } else if (Character.isWhitespace(ch) && !inQuote) {
                if (cur.length() > 0) {
                    out.add(cur.toString());
                    cur.setLength(0);
                }
            } else {
                cur.append(ch);
            }
        }
        if (cur.length() > 0) {
            out.add(cur.toString());
        }
        return out;
    }
}
