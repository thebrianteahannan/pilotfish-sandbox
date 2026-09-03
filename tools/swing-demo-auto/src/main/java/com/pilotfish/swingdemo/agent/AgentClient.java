package com.pilotfish.swingdemo.agent;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;

import com.pilotfish.swingdemo.driver.Located;
import com.pilotfish.swingdemo.driver.Script;

/**
 * Host-side talk to {@link AgentMain} inside another Swing JVM.
 */
public final class AgentClient implements AutoCloseable {

    private final Socket socket;
    private final PrintWriter out;
    private final BufferedReader in;

    public AgentClient(int port) {
        try {
            socket = new Socket(InetAddress.getByName("127.0.0.1"), port);
            socket.setTcpNoDelay(true);
            out = new PrintWriter(new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);
            in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException("Cannot connect to Swing agent on 127.0.0.1:" + port, e);
        }
    }

    public void ping() {
        expectOk("PING");
    }

    public String windows() {
        String reply = request("WINDOWS");
        if (!reply.startsWith("OK")) {
            throw new IllegalStateException("WINDOWS -> " + reply);
        }
        return reply.length() > 3 ? reply.substring(3).strip() : "";
    }

    public void front() {
        expectOk("FRONT");
    }

    public void activate(Script.Target target, boolean doubleClick) {
        String prefix = doubleClick ? "ACTIVATE double=true " : "ACTIVATE ";
        expectOk(prefix + toSpec(target));
    }

    public void dump(Path path) {
        expectOk("DUMP " + path.toAbsolutePath());
    }

    public Located find(Script.Target target) {
        return find(target, 4_000);
    }

    public Located find(Script.Target target, long timeoutMs) {
        String reply = request("FIND timeout=" + timeoutMs + " " + toSpec(target));
        if (reply.startsWith("FOUND ")) {
            return Located.parse(reply.substring(6));
        }
        throw new IllegalStateException(reply);
    }

    public void quit() {
        try {
            request("QUIT");
        } catch (Exception ignored) {
            // agent may close first
        }
    }

    private void expectOk(String command) {
        String reply = request(command);
        if (!reply.startsWith("OK")) {
            throw new IllegalStateException(command + " -> " + reply);
        }
    }

    private String request(String command) {
        out.println(command);
        try {
            String reply = in.readLine();
            if (reply == null) {
                throw new IllegalStateException("Agent closed the connection after " + command);
            }
            return reply;
        } catch (IllegalStateException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalStateException("Agent I/O failed for " + command, e);
        }
    }

    static String toSpec(Script.Target target) {
        StringBuilder sb = new StringBuilder();
        append(sb, "name", target.name);
        append(sb, "text", target.text);
        append(sb, "contains", target.contains);
        append(sb, "type", target.type);
        append(sb, "window", target.window);
        if (target.column != null) {
            append(sb, "column", String.valueOf(target.column));
        }
        if (target.row != null) {
            append(sb, "row", String.valueOf(target.row));
        }
        append(sb, "side", target.side);
        return sb.toString().strip();
    }

    private static void append(StringBuilder sb, String key, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        if (sb.length() > 0) {
            sb.append(' ');
        }
        sb.append(key).append('=').append('"').append(value.replace("\"", "")).append('"');
    }

    @Override
    public void close() {
        try {
            socket.close();
        } catch (Exception ignored) {
            // already closed
        }
    }
}
