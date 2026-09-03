package com.pilotfish.eip.gui.mapper.util;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.apache.xalan.extensions.ExpressionContext;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/** 26R1 no longer ships this Data Mapper helper; CRL XSLT still calls it. */
public final class TabDelimitedFileUtil {
  private TabDelimitedFileUtil() {}

  public static String getTargetValueFromFile(String filePath, String sourceValue) {
    if (sourceValue == null || sourceValue.isEmpty()) {
      return "";
    }
    if (filePath == null || filePath.isBlank()) {
      return sourceValue;
    }
    Path path = Path.of(filePath.replace('\\', '/'));
    if (!Files.isRegularFile(path)) {
      return sourceValue;
    }
    try {
      for (String line : Files.readAllLines(path, StandardCharsets.UTF_8)) {
        if (line.isBlank() || line.startsWith("#")) {
          continue;
        }
        String[] parts = line.split("\\t", 2);
        if (parts[0].trim().equals(sourceValue.trim())) {
          return parts.length > 1 ? parts[1].trim() : sourceValue;
        }
      }
    } catch (IOException ignored) {
      return sourceValue;
    }
    return sourceValue;
  }

  public static String getTargetValueFromFile(ExpressionContext ctx, String filePath, NodeList source) {
    return getTargetValueFromFile(filePath, first(source));
  }

  public static String getTargetValueFromFile(ExpressionContext ctx, NodeList filePath, NodeList source) {
    return getTargetValueFromFile(first(filePath), first(source));
  }

  public static String getTargetValueFromFile(ExpressionContext ctx, NodeList source) {
    return first(source);
  }

  public static String getTargetValueFromFile(NodeList filePath, NodeList source) {
    return getTargetValueFromFile(first(filePath), first(source));
  }

  private static String first(NodeList nodes) {
    if (nodes == null || nodes.getLength() == 0) {
      return "";
    }
    Node node = nodes.item(0);
    String value = node.getNodeValue();
    if (value != null && !value.isBlank()) {
      return value;
    }
    String text = node.getTextContent();
    return text == null ? "" : text.trim();
  }
}
