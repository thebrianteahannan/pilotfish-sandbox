package com.pilotfish.swingdemo.driver;

import java.awt.Component;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;

import javax.swing.AbstractButton;
import javax.swing.JList;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTree;
import javax.swing.SwingUtilities;

/**
 * Apply a script target inside the Swing JVM so a screen overlay cannot
 * steal the Robot click.
 */
public final class ComponentActivator {

    private ComponentActivator() {
    }

    public static void activate(Script.Target target, boolean doubleClick) throws Exception {
        Component found = ComponentFinder.forShowingWindows(4_000).waitFor(target);
        SwingUtilities.invokeAndWait(() -> apply(found, target, doubleClick));
    }

    private static void apply(Component found, Script.Target target, boolean doubleClick) {
        if (found instanceof JTable table) {
            int row = 0;
            int col = 0;
            if (target.column != null) {
                row = target.row == null ? 0 : target.row;
                col = target.column;
            } else if (ComponentFinder.hasText(target)) {
                int[] hit = ComponentFinder.tableHit(
                        table, ComponentFinder.firstText(target), target.contains != null);
                if (hit == null) {
                    throw new IllegalStateException("activate: table cell missing");
                }
                row = hit[0];
                col = hit[1];
            }
            table.changeSelection(row, col, false, false);
            table.requestFocusInWindow();
            Rectangle cell = table.getCellRect(row, col, true);
            fireClicks(table, cell.x + Math.max(1, cell.width / 2), cell.y + Math.max(1, cell.height / 2),
                    doubleClick ? 2 : 1);
            return;
        }
        if (found instanceof AbstractButton button) {
            // Mouse events, not doClick — a modal file dialog would block the EDT.
            fireClicks(button, Math.max(1, button.getWidth() / 2), Math.max(1, button.getHeight() / 2), 1);
            return;
        }
        if (found instanceof JTabbedPane tabs && ComponentFinder.hasText(target)) {
            int index = ComponentFinder.tabIndex(
                    tabs, ComponentFinder.firstText(target), target.contains != null);
            if (index >= 0) {
                tabs.setSelectedIndex(index);
            }
            return;
        }
        if (found instanceof JList<?> list && ComponentFinder.hasText(target)) {
            int index = ComponentFinder.listIndex(list, ComponentFinder.firstText(target));
            if (index >= 0) {
                list.setSelectedIndex(index);
                list.ensureIndexIsVisible(index);
            }
            fireClicks(list, list.getWidth() / 2, list.getHeight() / 2, doubleClick ? 2 : 1);
            return;
        }
        if (found instanceof JTree tree && ComponentFinder.hasText(target)) {
            int row = ComponentFinder.treeRow(
                    tree, ComponentFinder.firstText(target), target.contains != null);
            if (row >= 0) {
                tree.setSelectionRow(row);
                tree.scrollRowToVisible(row);
            }
            fireClicks(tree, 8, 8, doubleClick ? 2 : 1);
            return;
        }
        found.requestFocusInWindow();
        fireClicks(found, Math.max(1, found.getWidth() / 2), Math.max(1, found.getHeight() / 2),
                doubleClick ? 2 : 1);
    }

    private static void fireClicks(Component c, int x, int y, int count) {
        long when = System.currentTimeMillis();
        int max = Math.max(1, count);
        for (int n = 1; n <= max; n++) {
            c.dispatchEvent(new MouseEvent(
                    c, MouseEvent.MOUSE_PRESSED, when, MouseEvent.BUTTON1_DOWN_MASK,
                    x, y, n, false, MouseEvent.BUTTON1));
            c.dispatchEvent(new MouseEvent(
                    c, MouseEvent.MOUSE_RELEASED, when, 0,
                    x, y, n, false, MouseEvent.BUTTON1));
            c.dispatchEvent(new MouseEvent(
                    c, MouseEvent.MOUSE_CLICKED, when, 0,
                    x, y, n, false, MouseEvent.BUTTON1));
        }
    }
}
