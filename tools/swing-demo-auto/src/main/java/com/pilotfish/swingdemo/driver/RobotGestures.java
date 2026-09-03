package com.pilotfish.swingdemo.driver;

import java.awt.AWTException;
import java.awt.Component;
import java.awt.Container;
import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.Robot;
import java.awt.Toolkit;
import java.awt.Window;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.util.ArrayDeque;

import javax.swing.JComboBox;
import javax.swing.JList;
import javax.swing.SwingUtilities;
import javax.swing.text.JTextComponent;

/**
 * Video-friendly mouse and keyboard motion using {@link Robot}.
 */
public final class RobotGestures {

    private static final int MOVE_MS = 140;
    private static final int MOVE_STEPS = 12;

    private final Robot robot;

    public RobotGestures() {
        try {
            robot = new Robot();
        } catch (AWTException e) {
            throw new IllegalStateException(
                    "Cannot create java.awt.Robot. On macOS grant Accessibility to Terminal or Java.", e);
        }
        robot.setAutoDelay(12);
        robot.setAutoWaitForIdle(true);
    }

    public void click(Component component) {
        click(Located.of(component));
    }

    public void click(Located located) {
        moveFor(located);
        clickOnce();
        robot.delay(40);
    }

    public void drag(Located from, Located to) {
        moveFor(from);
        robot.delay(80);
        robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
        robot.delay(140);
        moveTo(to.centerX(), to.centerY());
        robot.delay(180);
        robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
        robot.delay(80);
    }

    public void doubleClick(Located located) {
        moveFor(located);
        clickOnce();
        robot.delay(45);
        clickOnce();
        robot.delay(40);
    }

    /**
     * Swing menus close if the pointer leaves the popup on a diagonal.
     * After a JMenu click, drop straight down, then sidestep onto the item.
     */
    public void hover(Located located) {
        moveFor(located);
        robot.delay(40);
    }

    private void moveFor(Located located) {
        int x = located.centerX();
        int y = located.centerY();
        if (isMenuItem(located)) {
            Point start = MouseInfo.getPointerInfo().getLocation();
            moveTo(start.x, y);
            moveTo(x, y);
        } else {
            moveTo(x, y);
        }
    }

    private static boolean isMenuItem(Located located) {
        String type = located.type == null ? "" : located.type;
        return type.contains("MenuItem") && !type.equals("JMenu");
    }

    public void pressEscape() {
        tap(KeyEvent.VK_ESCAPE, false);
    }

    private void clickOnce() {
        robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
        robot.delay(55);
        robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
    }

    public void typeInto(Component component, String text) {
        click(component);
        if (component instanceof JTextComponent) {
            selectAll();
        }
        typeText(text);
    }

    public void typeInto(Located located, String text) {
        click(located);
        selectAll();
        typeText(text);
    }

    public void typeText(String text) {
        for (int i = 0; i < text.length(); i++) {
            typeChar(text.charAt(i));
        }
        robot.delay(80);
    }

    public void pause(int ms) {
        robot.delay(Math.max(0, ms));
    }

    public void pressEnter() {
        tap(KeyEvent.VK_ENTER, false);
    }

    public void pageDown() {
        tap(KeyEvent.VK_PAGE_DOWN, false);
        robot.delay(80);
    }

    public void select(Component component, String itemText) {
        if (!(component instanceof JComboBox<?> combo)) {
            throw new IllegalArgumentException("select requires a JComboBox, got " + component.getClass().getName());
        }
        click(combo);
        robot.delay(180);
        try {
            JList<?> list = waitForShowingList(900);
            int index = indexOf(list, itemText);
            if (index < 0) {
                throw new IllegalStateException("Combo item not found: " + itemText);
            }
            Rectangle cell = cellBounds(list, index);
            Point origin = locationOnScreen(list);
            moveTo(origin.x + cell.x + cell.width / 2, origin.y + cell.y + cell.height / 2);
            robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
            robot.delay(55);
            robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
            robot.delay(100);
        } catch (IllegalStateException e) {
            typeAheadSelect(itemText);
        }
    }

    private void typeAheadSelect(String itemText) {
        for (int i = 0; i < itemText.length(); i++) {
            typeChar(itemText.charAt(i));
        }
        tap(KeyEvent.VK_ENTER, false);
        robot.delay(80);
    }

    public void moveTo(Component component) {
        Point p = locationOnScreen(component);
        int w = Math.max(1, component.getWidth());
        int h = Math.max(1, component.getHeight());
        moveTo(p.x + w / 2, p.y + h / 2);
    }

    void moveTo(int x, int y) {
        Point start = MouseInfo.getPointerInfo().getLocation();
        for (int i = 1; i <= MOVE_STEPS; i++) {
            double t = i / (double) MOVE_STEPS;
            double eased = t * t * (3 - 2 * t);
            int cx = (int) Math.round(start.x + (x - start.x) * eased);
            int cy = (int) Math.round(start.y + (y - start.y) * eased);
            robot.mouseMove(cx, cy);
            robot.delay(Math.max(1, MOVE_MS / MOVE_STEPS));
        }
        robot.mouseMove(x, y);
    }

    private void selectAll() {
        int modifier = Toolkit.getDefaultToolkit().getMenuShortcutKeyMaskEx();
        robot.keyPress(modifier);
        robot.keyPress(KeyEvent.VK_A);
        robot.delay(30);
        robot.keyRelease(KeyEvent.VK_A);
        robot.keyRelease(modifier);
        robot.delay(40);
    }

    private void typeChar(char ch) {
        if (ch == '\n') {
            tap(KeyEvent.VK_ENTER, false);
            return;
        }
        if (ch == '\t') {
            tap(KeyEvent.VK_TAB, false);
            return;
        }
        int key = KeyEvent.getExtendedKeyCodeForChar(ch);
        if (key == KeyEvent.VK_UNDEFINED) {
            throw new IllegalArgumentException("Cannot type character: " + ch);
        }
        boolean shift = Character.isUpperCase(ch) || "~!@#$%^&*()_+{}|:\"<>?".indexOf(ch) >= 0;
        tap(key, shift);
    }

    private void tap(int key, boolean shift) {
        if (shift) {
            robot.keyPress(KeyEvent.VK_SHIFT);
        }
        robot.keyPress(key);
        robot.delay(28);
        robot.keyRelease(key);
        if (shift) {
            robot.keyRelease(KeyEvent.VK_SHIFT);
        }
        robot.delay(18);
    }

    private JList<?> waitForShowingList(long timeoutMs) {
        long deadline = System.currentTimeMillis() + timeoutMs;
        while (System.currentTimeMillis() < deadline) {
            JList<?> list = findShowingList();
            if (list != null) {
                return list;
            }
            robot.delay(40);
        }
        throw new IllegalStateException("Combo popup list did not appear");
    }

    private JList<?> findShowingList() {
        final JList<?>[] holder = new JList<?>[1];
        try {
            SwingUtilities.invokeAndWait(() -> {
                for (Window window : Window.getWindows()) {
                    if (!window.isShowing()) {
                        continue;
                    }
                    JList<?> list = findList(window);
                    if (list != null && list.isShowing()) {
                        holder[0] = list;
                        return;
                    }
                }
            });
        } catch (Exception e) {
            throw new IllegalStateException("Failed to locate combo popup", e);
        }
        return holder[0];
    }

    private static JList<?> findList(Container root) {
        ArrayDeque<Component> q = new ArrayDeque<>();
        q.add(root);
        while (!q.isEmpty()) {
            Component c = q.removeFirst();
            if (c instanceof JList<?> list) {
                return list;
            }
            if (c instanceof Container container) {
                for (Component child : container.getComponents()) {
                    q.add(child);
                }
            }
        }
        return null;
    }

    private static int indexOf(JList<?> list, String itemText) {
        final int[] index = { -1 };
        try {
            SwingUtilities.invokeAndWait(() -> {
                for (int i = 0; i < list.getModel().getSize(); i++) {
                    Object value = list.getModel().getElementAt(i);
                    if (itemText.equals(String.valueOf(value))) {
                        index[0] = i;
                        return;
                    }
                }
            });
        } catch (Exception e) {
            throw new IllegalStateException("Failed to read combo items", e);
        }
        return index[0];
    }

    private static Rectangle cellBounds(JList<?> list, int index) {
        final Rectangle[] cell = new Rectangle[1];
        try {
            SwingUtilities.invokeAndWait(() -> cell[0] = list.getCellBounds(index, index));
        } catch (Exception e) {
            throw new IllegalStateException("Failed to read combo cell bounds", e);
        }
        if (cell[0] == null) {
            throw new IllegalStateException("No cell bounds for combo index " + index);
        }
        return cell[0];
    }

    private static Point locationOnScreen(Component component) {
        final Point[] point = new Point[1];
        try {
            SwingUtilities.invokeAndWait(() -> point[0] = component.getLocationOnScreen());
        } catch (Exception e) {
            throw new IllegalStateException("Component is not on screen", e);
        }
        return point[0];
    }
}
