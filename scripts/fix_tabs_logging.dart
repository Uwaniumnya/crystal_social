#!/usr/bin/env dart

import 'dart:io';

/// Script to replace all print statements with debugPrint in the tabs folder
/// This ensures production-safe logging across all tab files
void main() async {
  final tabsDir = Directory('lib/tabs');
  
  if (!await tabsDir.exists()) {
    print('Tabs directory not found!');
    return;
  }
  
  // Get all Dart files in tabs directory
  final dartFiles = await tabsDir
      .list(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();
  
  print('Found ${dartFiles.length} Dart files in tabs directory');
  
  for (final file in dartFiles) {
    print('Processing: ${file.path}');
    await processFile(file);
  }
  
  print('Completed processing all tab files!');
}

Future<void> processFile(File file) async {
  try {
    String content = await file.readAsString();
    
    // Replace print statements with debugPrint
    final replacements = [
      // Error print statements
      RegExp(r"print\('Error([^']*)'([^)]*)\)"),
      // General print statements that should be debug only
      RegExp(r"print\('([^']*)'([^)]*)\)"),
      // Console log statements
      RegExp(r"console\.log\(([^)]*)\)"),
    ];
    
    bool modified = false;
    
    for (final regex in replacements) {
      if (regex.hasMatch(content)) {
        if (regex.pattern.contains('Error')) {
          content = content.replaceAllMapped(regex, (match) {
            return "debugPrint('Error${match.group(1)}'${match.group(2) ?? ''})";
          });
        } else {
          content = content.replaceAllMapped(regex, (match) {
            return "debugPrint('${match.group(1)}'${match.group(2) ?? ''})";
          });
        }
        modified = true;
      }
    }
    
    // Add import for flutter/foundation.dart if debugPrint is used and import doesn't exist
    if (modified && content.contains('debugPrint') && !content.contains("import 'package:flutter/foundation.dart'")) {
      // Find the last import statement
      final importRegex = RegExp(r"import '[^']*';");
      final matches = importRegex.allMatches(content).toList();
      
      if (matches.isNotEmpty) {
        final lastImport = matches.last;
        final insertPosition = lastImport.end;
        content = content.substring(0, insertPosition) + 
                 "\nimport 'package:flutter/foundation.dart';" + 
                 content.substring(insertPosition);
      } else {
        // If no imports found, add at the beginning
        content = "import 'package:flutter/foundation.dart';\n" + content;
      }
    }
    
    if (modified) {
      await file.writeAsString(content);
      print('  ✅ Updated ${file.path}');
    } else {
      print('  ➖ No changes needed for ${file.path}');
    }
    
  } catch (e) {
    print('  ❌ Error processing ${file.path}: $e');
  }
}
