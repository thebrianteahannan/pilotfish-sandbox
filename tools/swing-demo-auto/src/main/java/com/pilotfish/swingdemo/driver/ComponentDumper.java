package com.pilotfish.swingdemo.driver;

import java.awt.Component;
import java.awt.Container;
import java.awt.Rectangle;
import java.awt.Window;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import javax.swing.JFrame;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTree;
import javax.swing.SwingUtilities;

/**
 * Writes the showing Swing tree so we can author YAML targets.
 */
public final class ComponentDumper {

    private ComponentDumper() {
    }

    public static void writeShowing(Path path) {
        try {
            String[] holder = new String[1];
            SwingUtilities.invokeAndWait(() -> holder[0] = dumpShowing());
            Path parent = path.toAbsolutePath().getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }
            Files.writeString(path, holder[0], StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("Cannot dump component tree to " + path, e);
        }
    }

    static String dumpShowing() {
        StringBuilder sb = new StringBuilder();
        Window[] windows = Window.getWindows();
        int shown = 0;
        for (Window window : windows) {
            if (!window.isShowing()) {
                continue;
            }
            shown++;
            String title = window instanceof JFrame frame ? frame.getTitle() : window.getClass().getSimpleName();
            sb.append("WINDOW \"").append(title).append("\" ")
                    .append(window.getWidth()).append('x').append(window.getHeight())
                    .append(" ").append(window.getClass().getSimpleName())
                    .append('\n');
            walk(window, "  ", sb);
        }
        if (shown == 0) {
            sb.append("(no showing windows)\n");
        }
        return sb.toString();
    }

    private static void walk(Component c, String indent, StringBuilder sb) {
        if (!c.isShowing()) {
            return;
        }
        String text = ComponentFinder.normalizeText(ComponentFinder.visibleText(c));
        if (text.length() > 80) {
            text = text.substring(0, 77) + "...";
        }
        String typeName = c.getClass().getSimpleName();
        if (typeName.isBlank()) {
            typeName = c.getClass().getName();
        }
        sb.append(indent).append(typeName);
        if (c.getName() != null && !c.getName().isBlank()) {
            sb.append(" name=").append(c.getName());
        }
        if (!text.isBlank()) {
            sb.append(" text=\"").append(text.replace("\"", "'")).append('"');
        }
        if (c instanceof javax.swing.AbstractButton button) {
            String tip = button.getToolTipText();
            if (tip != null && !tip.isBlank()) {
                sb.append(" tip=\"").append(tip.replace("\"", "'")).append('"');
            }
        }
        sb.append(" ").append(c.getWidth()).append('x').append(c.getHeight());
        sb.append('\n');
        if (c instanceof JTree tree) {
            dumpTreeRows(tree, indent + "  ", sb);
        }
        if (c instanceof JTabbedPane tabs) {
            for (int i = 0; i < tabs.getTabCount(); i++) {
                sb.append(indent).append("  tab[\"").append(tabs.getTitleAt(i)).append("\"]\n");
            }
        }
        if (c instanceof JTable table) {
            dumpTable(table, indent + "  ", sb);
        }
        if (c instanceof Container container) {
            for (Component child : container.getComponents()) {
                walk(child, indent + "  ", sb);
            }
        }
    }

    private static void dumpTreeRows(JTree tree, String indent, StringBuilder sb) {
        int last = -1;
        int guard = 0;
        while (tree.getRowCount() != last && guard++ < 20) {
            last = tree.getRowCount();
            for (int i = 0; i < tree.getRowCount(); i++) {
                tree.expandRow(i);
            }
        }
        for (int i = 0; i < tree.getRowCount(); i++) {
            var path = tree.getPathForRow(i);
            if (path == null) {
                continue;
            }
            String label = ComponentFinder.normalizeText(tree.convertValueToText(
                    path.getLastPathComponent(), false, tree.isExpanded(i), true, i, false));
            sb.append(indent).append("row[\"").append(label).append("\"]\n");
        }
    }

    private static void dumpTable(JTable table, String indent, StringBuilder sb) {
        int rows = Math.min(table.getRowCount(), 40);
        int cols = table.getColumnCount();
        StringBuilder headers = new StringBuilder();
        for (int col = 0; col < cols; col++) {
            if (headers.length() > 0) {
                headers.append(" | ");
            }
            headers.append(col).append('=').append(ComponentFinder.normalizeText(table.getColumnName(col)));
        }
        sb.append(indent).append("table name=").append(table.getName() == null ? "" : table.getName())
                .append(" ").append(table.getRowCount()).append('x').append(cols)
                .append(" rowH=").append(table.getRowHeight())
                .append(" cols[").append(headers).append("]\n");
        for (int row = 0; row < rows; row++) {
            StringBuilder line = new StringBuilder();
            for (int col = 0; col < cols; col++) {
                Object value = table.getValueAt(row, col);
                String label = ComponentFinder.normalizeText(value == null ? "" : String.valueOf(value));
                if (label.isBlank()) {
                    continue;
                }
                if (line.length() > 0) {
                    line.append(" | ");
                }
                line.append(label);
            }
            if (line.length() > 0) {
                sb.append(indent).append("cell[\"").append(line).append("\"]\n");
            }
        }
        for (int row = 0; row < rows; row++) {
            for (int col = 0; col < cols; col++) {
                dumpRenderer(table, row, col, indent, sb);
            }
        }
    }

    private static void dumpRenderer(JTable table, int row, int col, String indent, StringBuilder sb) {
        try {
            Object value = table.getValueAt(row, col);
            var renderer = table.getCellRenderer(row, col);
            Component comp = renderer.getTableCellRendererComponent(
                    table, value, false, false, row, col);
            if (comp == null) {
                return;
            }
            Rectangle cell = table.getCellRect(row, col, true);
            sb.append(indent).append("render[").append(row).append(',').append(col)
                    .append("] ").append(comp.getClass().getSimpleName())
                    .append(" cell=").append(cell.width).append('x').append(cell.height)
                    .append('\n');
            dumpRendererTree(comp, indent + "  ", sb);
        } catch (Exception e) {
            sb.append(indent).append("render[").append(row).append(',').append(col)
                    .append("] ERROR ").append(e.getMessage()).append('\n');
        }
    }

    private static void dumpRendererTree(Component c, String indent, StringBuilder sb) {
        String text = ComponentFinder.normalizeText(ComponentFinder.visibleText(c));
        if (text.length() > 80) {
            text = text.substring(0, 77) + "...";
        }
        sb.append(indent).append(c.getClass().getSimpleName());
        if (c.getName() != null && !c.getName().isBlank()) {
            sb.append(" name=").append(c.getName());
        }
        if (!text.isBlank()) {
            sb.append(" text=\"").append(text.replace("\"", "'")).append('"');
        }
        sb.append(" ").append(c.getWidth()).append('x').append(c.getHeight()).append('\n');
        if (c instanceof Container container) {
            for (Component child : container.getComponents()) {
                dumpRendererTree(child, indent + "  ", sb);
            }
        }
    }
}
