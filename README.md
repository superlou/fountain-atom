# Fountain Support for Atom
This package aims to provide syntax highlighting and utilities to improve the experience of screenwriting with the [Fountain](http://fountain.io/) syntax.

*Note: The formatted preview has been switched to use Afterwriting.  This provides a much more robust implementation of the Fountain formatting standards and makes export to PDF directly from Atom possible.  The previous Fountain preview is still accessible from the command palette but is deprecated and will be removed in a future release.  If the new functionality does not satisfy your use case, please open an issue!*

## Features:
* Outline list navigator (<kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>o</kbd>)
* **[new!]** PDF preview (<kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>shift</kbd> <kbd>m</kbd>)
* **[new!]** PDF export (<kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>shift</kbd> <kbd>x</kbd>)
* **[new!]** PDF preview and export configuration in the package settings
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

Included fonts for PDF export and preview:

* [AnonymousPro](https://fontlibrary.org/en/font/anonymous-pro)
* [CourierCode](https://fontlibrary.org/en/font/courier-code)
* [CourierPrime](https://fontlibrary.org/en/font/courier-prime)
* [GNUTypewriter](https://fontlibrary.org/en/font/gnutypewriter)

Please open issues with feature requests that would improve your work flow.

## Outline view in action:
![outline view](https://github.com/superlou/fountain-atom/blob/master/screenshot.gif?raw=true)
