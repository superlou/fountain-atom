# Fountain Support for Atom
This package aims to provide syntax highlighting and utilities to improve the experience of screenwriting with the [Fountain](http://fountain.io/) syntax.

## Features:
* Outline list navigator (<kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>o</kbd>)
* PDF preview (<kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>shift</kbd> <kbd>m</kbd>)
* PDF export (<kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>shift</kbd> <kbd>x</kbd>)
* Symbol listing via the [symbols-view package](https://github.com/atom/symbols-view) (<kbd>crtl</kbd> <kbd>r</kbd>)

## Notes:
* HTML formatted preview \(previously triggered by <kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>shift</kbd> <kbd>m</kbd>\), is now deprecated.
* If you encounter problems generating PDFs \(for preview or export\), please log an [issue](https://github.com/superlou/fountain-atom/issues).
* Access to legacy preview can be found under "fountain:preview_legacy" using <kbd>ctrl</kbd> <kbd>shift</kbd> <kbd>p</kbd>.

## Development
This is currently a work in progress, pulling from a few different tools:

* HTML preview support from [Fountain.js](https://github.com/mattdaly/Fountain.js)
* Syntax highlighting based on [The Candler Blog](http://www.candlerblog.com/2012/09/10/fountain-for-sublime-text/)
* PDF exporting provided by [Afterwriting CLI](https://github.com/ifrost/afterwriting-labs)
* PDF preview rendered by atom [pdf-view](https://atom.io/packages/pdf-view) package

Please open issues with feature requests that would improve your work flow.

## Outline view in action:
![outline view](https://github.com/superlou/fountain-atom/blob/outlook-view/screenshot.gif?raw=true)
