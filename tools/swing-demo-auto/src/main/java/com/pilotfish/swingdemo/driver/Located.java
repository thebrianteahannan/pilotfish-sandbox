package com.pilotfish.swingdemo.driver;

import java.awt.Component;
import java.awt.Rectangle;

import javax.swing.JList;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTree;

/**
 * Screen-space bounds for a widget. Used so Robot can click in our JVM
 * while an agent in another JVM only reports coordinates.
 */
public final class Located {

    public final int x;
    public final int y;
    public final int width;
    public final int height;
    public final String type;

    public Located(int x, int y, int width, int height, String type) {
        this.x = x;
        this.y = y;
        this.width = Math.max(1, width);
        this.height = Math.max(1, height);
        this.type = type == null ? "" : type;
    }

    public int centerX() {
        return x + width / 2;
    }

    public int centerY() {
        return y + height / 2;
    }

    public static Located of(Component component) {
        var p = component.getLocationOnScreen();
        return new Located(p.x, p.y, component.getWidth(), component.getHeight(),
                component.getClass().getSimpleName());
    }

    public static Located ofListItem(JList<?> list, String text) {
        Rectangle cell = ComponentFinder.listItemBounds(list, text);
        return new Located(cell.x, cell.y, cell.width, cell.height, "JList");
    }

    public static Located ofTreeRow(JTree tree, String text, boolean contains) {
        Rectangle cell = ComponentFinder.treeRowBounds(tree, text, contains);
        return new Located(cell.x, cell.y, cell.width, cell.height, "JTree");
    }

    public static Located ofTab(JTabbedPane tabs, String text) {
        Rectangle cell = ComponentFinder.tabBounds(tabs, text);
        return new Located(cell.x, cell.y, cell.width, cell.height, "JTabbedPane");
    }

    public static Located ofTableCell(JTable table, String text, boolean contains) {
        Rectangle cell = ComponentFinder.tableCellBounds(table, text, contains);
        return new Located(cell.x, cell.y, cell.width, cell.height, "JTable");
    }

    public static Located ofTableCellAt(JTable table, int row, int column) {
        Rectangle cell = ComponentFinder.tableCellBoundsAt(table, row, column);
        return new Located(cell.x, cell.y, cell.width, cell.height, "JTable");
    }

    public static Located parse(String line) {
        String[] p = line.trim().split("\\s+");
        if (p.length < 5) {
            throw new IllegalArgumentException("Bad FOUND line: " + line);
        }
        return new Located(
                Integer.parseInt(p[0]),
                Integer.parseInt(p[1]),
                Integer.parseInt(p[2]),
                Integer.parseInt(p[3]),
                p.length > 4 ? p[4] : "");
    }

    public String toWire() {
        return x + " " + y + " " + width + " " + height + " " + type.replace(' ', '_');
    }
}
