package com.pilotfish.swingdemo.driver;

import java.awt.Component;
import java.awt.Container;
import java.awt.Rectangle;
import java.awt.Window;
import java.util.ArrayDeque;
import java.util.Locale;

import javax.swing.AbstractButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTree;
import javax.swing.SwingUtilities;
import javax.swing.text.JTextComponent;

/**
 * Walks a Swing tree and matches widgets by name, visible text, and type.
 */
public final class ComponentFinder {

    private final Container root;
    private final long timeoutMs;

    public ComponentFinder(Container root, long timeoutMs) {
        this.root = root;
        this.timeoutMs = timeoutMs;
    }

    public static ComponentFinder forShowingWindows(long timeoutMs) {
        return new ComponentFinder(null, timeoutMs);
    }

    public Component waitFor(Script.Target target) {
        if (target == null || target.isEmpty()) {
            throw new IllegalArgumentException("Step target is required");
        }
        long deadline = System.currentTimeMillis() + timeoutMs;
        Exception last = null;
        while (System.currentTimeMillis() < deadline) {
            try {
                Component found = invokeFind(target);
                if (found != null && found.isShowing()) {
                    return found;
                }
            } catch (Exception e) {
                last = e;
            }
            sleep(50);
        }
        throw new IllegalStateException(
                "Timed out waiting for component [" + target + "]"
                        + (last == null ? "" : ": " + last.getMessage()));
    }

    Component findNow(Script.Target target) {
        ArrayDeque<Component> q = new ArrayDeque<>();
        if (root != null) {
            q.add(root);
        } else {
            for (Window window : Window.getWindows()) {
                if (!window.isShowing()) {
                    continue;
                }
                if (target.window != null && !target.window.isBlank()) {
                    String title = windowTitle(window);
                    if (!title.toLowerCase(Locale.ROOT).contains(target.window.toLowerCase(Locale.ROOT))) {
                        continue;
                    }
                }
                q.add(window);
            }
        }
        java.util.List<Component> hits = new java.util.ArrayList<>();
        boolean bySide = target.side != null && !target.side.isBlank();
        while (!q.isEmpty()) {
            Component c = q.removeFirst();
            if (matches(c, target)) {
                if (!bySide) {
                    return c;
                }
                if (c.isShowing()) {
                    hits.add(c);
                }
            }
            if (c instanceof javax.swing.JFrame frame && frame.getJMenuBar() != null) {
                q.add(frame.getJMenuBar());
            }
            if (c instanceof javax.swing.JRootPane root && root.getJMenuBar() != null) {
                q.add(root.getJMenuBar());
            }
            if (c instanceof Container container) {
                for (Component child : container.getComponents()) {
                    q.add(child);
                }
            }
        }
        if (!bySide || hits.isEmpty()) {
            return null;
        }
        return pickSide(hits, target.side);
    }

    public Located locate(Script.Target target) {
        Component found = waitFor(target);
        if (found instanceof JList<?> list && hasText(target)) {
            return Located.ofListItem(list, firstText(target));
        }
        if (found instanceof JTree tree && hasText(target)) {
            return Located.ofTreeRow(tree, firstText(target), target.contains != null);
        }
        if (found instanceof JTabbedPane tabs && hasText(target)) {
            return Located.ofTab(tabs, firstText(target));
        }
        if (found instanceof JTable table && (hasText(target) || target.column != null)) {
            if (target.column != null) {
                int row = target.row == null ? 0 : target.row;
                return Located.ofTableCellAt(table, row, target.column);
            }
            return Located.ofTableCell(table, firstText(target), target.contains != null);
        }
        return Located.of(found);
    }

    static Component pickSide(java.util.List<Component> hits, String side) {
        String want = side.trim().toLowerCase(Locale.ROOT);
        Component best = hits.get(0);
        int bestX = Integer.MIN_VALUE;
        boolean right = "right".equals(want) || "target".equals(want);
        if (!right) {
            bestX = Integer.MAX_VALUE;
        }
        for (Component c : hits) {
            int x;
            try {
                x = c.getLocationOnScreen().x;
            } catch (Exception e) {
                continue;
            }
            if (right ? x > bestX : x < bestX) {
                bestX = x;
                best = c;
            }
        }
        return best;
    }

    static boolean hasText(Script.Target target) {
        return (target.text != null && !target.text.isBlank())
                || (target.contains != null && !target.contains.isBlank());
    }

    static String firstText(Script.Target target) {
        return target.text != null && !target.text.isBlank() ? target.text : target.contains;
    }

    private Component invokeFind(Script.Target target) throws Exception {
        if (SwingUtilities.isEventDispatchThread()) {
            return findNow(target);
        }
        final Component[] holder = new Component[1];
        SwingUtilities.invokeAndWait(() -> holder[0] = findNow(target));
        return holder[0];
    }

    static boolean matches(Component c, Script.Target target) {
        if (target.name != null && !target.name.isBlank()) {
            if (!target.name.equals(c.getName())) {
                return false;
            }
        }
        if (target.type != null && !target.type.isBlank() && !typeMatches(c, target.type)) {
            return false;
        }
        if (target.text != null && !target.text.isBlank() && !textMatches(c, target.text)) {
            return false;
        }
        if (target.contains != null && !target.contains.isBlank() && !containsText(c, target.contains)) {
            return false;
        }
        return true;
    }

    static boolean typeMatches(Component c, String type) {
        String want = type.trim();
        String simple = c.getClass().getSimpleName();
        String fqcn = c.getClass().getName();
        if (want.equalsIgnoreCase(simple) || want.equalsIgnoreCase(fqcn)) {
            return true;
        }
        String compact = want.replace(" ", "").toLowerCase(Locale.ROOT);
        if ("button".equals(compact) && c instanceof AbstractButton && !(c instanceof JMenuItem)) {
            return true;
        }
        if (("textfield".equals(compact) || "field".equals(compact)) && c instanceof JTextComponent) {
            return true;
        }
        if (("combo".equals(compact) || "combobox".equals(compact)) && c instanceof JComboBox) {
            return true;
        }
        if ("label".equals(compact) && c instanceof JLabel) {
            return true;
        }
        if ("list".equals(compact) && c instanceof JList) {
            return true;
        }
        if ("menu".equals(compact) && c instanceof JMenu) {
            return true;
        }
        if (("menuitem".equals(compact) || "jmenuitem".equals(compact) || "radiomenuitem".equals(compact))
                && c instanceof JMenuItem) {
            return true;
        }
        if (("tree".equals(compact) || "formattree".equals(compact))
                && (c instanceof JTree || "FormatTree".equals(c.getClass().getSimpleName()))) {
            return true;
        }
        if ("tab".equals(compact) && c instanceof JTabbedPane) {
            return true;
        }
        if ("table".equals(compact) && c instanceof JTable) {
            return true;
        }
        return false;
    }

    static boolean textMatches(Component c, String expected) {
        if (c instanceof JList<?> list) {
            return listIndex(list, expected) >= 0;
        }
        if (c instanceof JTree tree) {
            return treeRow(tree, expected, false) >= 0;
        }
        if (c instanceof JTabbedPane tabs) {
            return tabIndex(tabs, expected, false) >= 0;
        }
        if (c instanceof JTable table) {
            return tableMatchesNeedle(table, expected, false);
        }
        String visible = normalizeText(visibleText(c));
        return visible != null && visible.equalsIgnoreCase(normalizeText(expected));
    }

    static boolean containsText(Component c, String needle) {
        String want = normalizeText(needle).toLowerCase(Locale.ROOT);
        if (c instanceof JList<?> list) {
            for (int i = 0; i < list.getModel().getSize(); i++) {
                String item = normalizeText(String.valueOf(list.getModel().getElementAt(i)));
                if (item.toLowerCase(Locale.ROOT).contains(want)) {
                    return true;
                }
            }
            return false;
        }
        if (c instanceof JTree tree) {
            return treeRow(tree, needle, true) >= 0;
        }
        if (c instanceof JTabbedPane tabs) {
            return tabIndex(tabs, needle, true) >= 0;
        }
        if (c instanceof JTable table) {
            return tableMatchesNeedle(table, needle, true);
        }
        String visible = normalizeText(visibleText(c));
        return visible != null && visible.toLowerCase(Locale.ROOT).contains(want);
    }

    static int listIndex(JList<?> list, String expected) {
        String want = normalizeText(expected);
        for (int i = 0; i < list.getModel().getSize(); i++) {
            String item = normalizeText(String.valueOf(list.getModel().getElementAt(i)));
            if (item.equalsIgnoreCase(want)) {
                return i;
            }
        }
        return -1;
    }

    static Rectangle listItemBounds(JList<?> list, String expected) {
        int index = listIndex(list, expected);
        if (index < 0) {
            throw new IllegalStateException("List item not found: " + expected);
        }
        Rectangle cell = list.getCellBounds(index, index);
        if (cell == null) {
            throw new IllegalStateException("No cell bounds for " + expected);
        }
        return new Rectangle(
                list.getLocationOnScreen().x + cell.x,
                list.getLocationOnScreen().y + cell.y,
                cell.width,
                cell.height);
    }

    static int treeRow(JTree tree, String expected, boolean contains) {
        expandTree(tree);
        String want = normalizeText(expected);
        for (int i = 0; i < tree.getRowCount(); i++) {
            var path = tree.getPathForRow(i);
            if (path == null) {
                continue;
            }
            String label = normalizeText(tree.convertValueToText(
                    path.getLastPathComponent(), false, tree.isExpanded(i), true, i, false));
            if (contains) {
                if (label.toLowerCase(Locale.ROOT).contains(want.toLowerCase(Locale.ROOT))) {
                    tree.scrollRowToVisible(i);
                    return i;
                }
            } else if (label.equalsIgnoreCase(want)) {
                tree.scrollRowToVisible(i);
                return i;
            }
        }
        return -1;
    }

    static Rectangle treeRowBounds(JTree tree, String expected, boolean contains) {
        int row = treeRow(tree, expected, contains);
        if (row < 0) {
            throw new IllegalStateException("Tree row not found: " + expected);
        }
        Rectangle cell = tree.getRowBounds(row);
        if (cell == null) {
            throw new IllegalStateException("No bounds for tree row " + expected);
        }
        return new Rectangle(
                tree.getLocationOnScreen().x + cell.x,
                tree.getLocationOnScreen().y + cell.y,
                cell.width,
                cell.height);
    }

    static int tabIndex(JTabbedPane tabs, String expected, boolean contains) {
        String want = normalizeText(expected);
        for (int i = 0; i < tabs.getTabCount(); i++) {
            String title = normalizeText(tabs.getTitleAt(i));
            if (contains) {
                if (title.toLowerCase(Locale.ROOT).contains(want.toLowerCase(Locale.ROOT))) {
                    return i;
                }
            } else if (title.equalsIgnoreCase(want)) {
                return i;
            }
        }
        return -1;
    }

    static boolean tableMatchesNeedle(JTable table, String expected, boolean contains) {
        String want = normalizeText(expected);
        if (want.isBlank()) {
            return false;
        }
        if (labelHit(table.getName(), want, contains)
                || labelHit(table.getClass().getSimpleName(), want, contains)) {
            return true;
        }
        for (int col = 0; col < table.getColumnCount(); col++) {
            if (labelHit(table.getColumnName(col), want, contains)) {
                return true;
            }
            try {
                Object header = table.getColumnModel().getColumn(col).getHeaderValue();
                if (header != null && labelHit(String.valueOf(header), want, contains)) {
                    return true;
                }
            } catch (Exception ignored) {
                // column model can be mid-rebuild
            }
        }
        return tableHit(table, expected, contains) != null;
    }

    static boolean labelHit(String raw, String want, boolean contains) {
        String label = normalizeText(raw);
        if (label.isBlank() || want == null || want.isBlank()) {
            return false;
        }
        if (contains) {
            return label.toLowerCase(Locale.ROOT).contains(want.toLowerCase(Locale.ROOT));
        }
        return label.equalsIgnoreCase(want);
    }

    static String rendererText(JTable table, int row, int col) {
        try {
            Object value = table.getValueAt(row, col);
            var renderer = table.getCellRenderer(row, col);
            Component painted = renderer.getTableCellRendererComponent(
                    table, value, false, false, row, col);
            return normalizeText(visibleText(painted));
        } catch (Exception e) {
            return "";
        }
    }

    static int[] tableHit(JTable table, String expected, boolean contains) {
        String want = normalizeText(expected);
        for (int row = 0; row < table.getRowCount(); row++) {
            for (int col = 0; col < table.getColumnCount(); col++) {
                Object value = table.getValueAt(row, col);
                String label = normalizeText(value == null ? "" : String.valueOf(value));
                boolean hit = contains
                        ? label.toLowerCase(Locale.ROOT).contains(want.toLowerCase(Locale.ROOT))
                        : label.equalsIgnoreCase(want);
                if (!hit && value != null) {
                    hit = labelHit(value.getClass().getSimpleName(), want, contains);
                }
                if (!hit) {
                    hit = labelHit(rendererText(table, row, col), want, contains);
                }
                if (hit) {
                    table.scrollRectToVisible(table.getCellRect(row, col, true));
                    return new int[] { row, col };
                }
            }
        }
        return null;
    }

    static Rectangle tableCellBoundsAt(JTable table, int row, int column) {
        if (row < 0 || row >= table.getRowCount() || column < 0 || column >= table.getColumnCount()) {
            throw new IllegalStateException("Table cell [" + row + "," + column + "] out of range");
        }
        table.scrollRectToVisible(table.getCellRect(row, column, true));
        Rectangle cell = table.getCellRect(row, column, true);
        return new Rectangle(
                table.getLocationOnScreen().x + cell.x,
                table.getLocationOnScreen().y + cell.y,
                Math.max(1, cell.width),
                Math.max(1, cell.height));
    }

    static Rectangle tableCellBounds(JTable table, String expected, boolean contains) {
        int[] hit = tableHit(table, expected, contains);
        if (hit == null) {
            throw new IllegalStateException("Table cell not found: " + expected);
        }
        Rectangle cell = table.getCellRect(hit[0], hit[1], true);
        return new Rectangle(
                table.getLocationOnScreen().x + cell.x,
                table.getLocationOnScreen().y + cell.y,
                Math.max(1, cell.width),
                Math.max(1, cell.height));
    }

    static Rectangle tabBounds(JTabbedPane tabs, String expected) {
        int index = tabIndex(tabs, expected, false);
        if (index < 0) {
            index = tabIndex(tabs, expected, true);
        }
        if (index < 0) {
            throw new IllegalStateException("Tab not found: " + expected);
        }
        Rectangle cell = tabs.getBoundsAt(index);
        if (cell == null) {
            throw new IllegalStateException("No bounds for tab " + expected);
        }
        return new Rectangle(
                tabs.getLocationOnScreen().x + cell.x,
                tabs.getLocationOnScreen().y + cell.y,
                cell.width,
                cell.height);
    }

    private static void expandTree(JTree tree) {
        int last = -1;
        int guard = 0;
        while (tree.getRowCount() != last && guard++ < 40) {
            last = tree.getRowCount();
            for (int i = 0; i < tree.getRowCount(); i++) {
                tree.expandRow(i);
            }
        }
    }

    static String windowTitle(Window window) {
        String title = "";
        if (window instanceof java.awt.Frame frame) {
            title = frame.getTitle();
        } else if (window instanceof java.awt.Dialog dialog) {
            title = dialog.getTitle();
        }
        String cls = window.getClass().getSimpleName();
        if (title == null || title.isBlank()) {
            return cls;
        }
        return title + " " + cls;
    }

    static String normalizeText(String raw) {
        if (raw == null) {
            return "";
        }
        String stripped = raw.replaceAll("(?is)<[^>]*>", " ").replace('&', ' ');
        return stripped.replaceAll("\\s+", " ").strip();
    }

    static String visibleText(Component c) {
        if (c instanceof AbstractButton button) {
            String text = button.getText();
            if (text != null && !text.isBlank()) {
                return text;
            }
            return button.getToolTipText();
        }
        if (c instanceof JLabel label) {
            return label.getText();
        }
        if (c instanceof JTextComponent field) {
            return field.getText();
        }
        if (c instanceof JComboBox<?> combo) {
            Object item = combo.getSelectedItem();
            return item == null ? "" : String.valueOf(item);
        }
        return null;
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while waiting for a component", e);
        }
    }
}
