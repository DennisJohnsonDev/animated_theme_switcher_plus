## 0.1.0

- Forked from [kherel/animated_theme_switcher](https://github.com/kherel/animated_theme_switcher) v2.0.10.
- Renamed package to `animated_theme_switcher_plus`.
- **Fix:** `AnimationController` in `ThemeProvider` is now properly disposed, preventing memory leaks and the "AnimationController was not disposed" assertion in debug mode.
- Migrated dev dependency from deprecated `pedantic` to `flutter_lints`.
- Updated example to use Flutter 3+ `TextTheme.bodyLarge` (replacing deprecated `bodyText1`).

---

## Upstream history (pre-fork)

## 2.0.10
  - remove the widget tree once the animation is finished

## 2.0.9
  - added custom offset to changeTheme method parameters
  - added onAnimationFinish callback
## 2.0.8
  - key fix
## 2.0.7
  - hot reaload fix
## 2.0.6
  - bug fix
## 2.0.5
  - grammar fixes )))
## 2.0.4
  - readme fix
## 2.0.3
  - fixes const Widget bug
## 2.0.2
  - update dependencies
  - update examples
  - fixes
## 2.0.1-nullsafety.0
  - hide builder inside themeProvider widget

## 2.0.0-nullsafety.0
  - Removed unnecessary 'android' and 'ios' folders
  - Migrated to null-safety
  - Removed deprecated code
  
## 1.0.9

  - supported platforms fix

## 1.0.8

  - add reverse animation feature
  - specify supported platforms // web not supported

## 1.0.7

- add example with shared shared_preferences

## 1.0.6

- add custom clipper 
- change background screenshot quality

## 1.0.5

- fix packages

## 1.0.4

- example updated
- bug fixed

## 1.0.3

- update readme.md

## 1.0.2

- longer description added

## 1.0.1

- changelog.md added

## 1.0.0

- Initial version