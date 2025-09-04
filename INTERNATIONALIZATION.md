# AnymeX Internationalization (i18n) Guide

This guide explains how to add and use internationalized strings in AnymeX.

## Overview

AnymeX uses Flutter's built-in internationalization support with ARB (Application Resource Bundle) files. The setup supports Weblate for collaborative translation.

## File Structure

```
lib/
├── l10n/
│   └── app_en.arb          # English translation template
└── main.dart               # Localization setup
l10n.yaml                   # L10n configuration
```

## Adding New Strings

### 1. Add to ARB File

Edit `lib/l10n/app_en.arb` and add your string:

```json
{
  "myNewString": "Hello World",
  "@myNewString": {
    "description": "A greeting message"
  }
}
```

### 2. For Strings with Parameters

```json
{
  "welcomeUser": "Welcome, {userName}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "John"
      }
    }
  }
}
```

### 3. For Pluralization

```json
{
  "itemCount": "{count, plural, =0{no items} =1{one item} other{{count} items}}",
  "@itemCount": {
    "description": "Number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

## Using Strings in Code

### 1. Import the Localizations

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### 2. Access in Widget

```dart
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  
  return Text(l10n?.myNewString ?? 'Fallback text');
}
```

### 3. With Parameters

```dart
Text(l10n?.welcomeUser('John') ?? 'Welcome, John!')
```

### 4. Null Safety Pattern

Always provide fallback text since `AppLocalizations.of(context)` can be null:

```dart
l10n?.stringKey ?? 'Fallback Text'
```

## Examples from AnymeX

### Navigation Labels
```dart
// ARB file
"home": "Home",
"@home": { "description": "Home navigation label" }

// Usage
label: AppLocalizations.of(context)?.home ?? 'Home'
```

### Parameterized Strings
```dart
// ARB file
"addGithubRepo": "Add github repo for {type}",
"@addGithubRepo": {
  "placeholders": {
    "type": { "type": "String", "examples": ["anime", "manga"] }
  }
}

// Usage
description: l10n?.addGithubRepo('anime') ?? 'Add github repo for anime'
```

## Development Workflow

1. **Add strings** to `lib/l10n/app_en.arb`
2. **Run generation**: `flutter gen-l10n` (when Flutter is available)
3. **Update code** to use the new strings
4. **Test** with fallback text

## Weblate Integration

The project is set up for Weblate integration:

- **Template file**: `lib/l10n/app_en.arb`
- **Configuration**: Ready for https://hosted.weblate.org
- **Future languages**: Will be added as `app_{locale}.arb` files

## Best Practices

1. **Use descriptive keys**: `settingsAccountsTitle` not `title1`
2. **Add descriptions**: Help translators understand context
3. **Group related strings**: Use consistent prefixes (`settings*`, `player*`)
4. **Provide examples**: Show how parameters are used
5. **Keep fallbacks**: Always provide English fallback text
6. **Test edge cases**: Long translations, special characters

## Common Patterns

### Settings Section
```json
"settingsAccounts": "Accounts",
"settingsAccountsDescription": "Manage your accounts"
```

### Actions
```json
"buttonSave": "Save",
"buttonCancel": "Cancel",
"buttonContinue": "Continue"
```

### Status Messages
```json
"statusLoading": "Loading...",
"statusError": "Something went wrong",
"statusSuccess": "Operation completed successfully"
```

This internationalization system provides a solid foundation for making AnymeX accessible to users worldwide.