{Emitter, Disposable, CompositeDisposable} = require 'atom'
{$, $$$, ScrollView} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
fountainParser = require './vendor/fountain-parser'
#PdfConverter = require './fountain-pdf-converter.coffee'

module.exports =
class FountainPreviewView extends ScrollView
  @content: ->
    @div class: 'fountain-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, @filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable
#    @pdfConverter = new PdfConverter()
    @loaded = false

  attached: ->
    return if @isAttached
    @isAttached = true

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(@filePath)
      else
        @disposables.add atom.packages.onDidActivateInitialPackages =>
          @subscribeToFilePath(@filePath)

  serialize: ->
    deserializer: 'FountainPreviewView'
    editorId: @editorId
    filePath: @getPath()

  destroy: ->
    @disposables.dispose()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    # No op to suppress deprecation warning
    new Disposable

  onDidChangeFountain: (callback) ->
    @emitter.on 'did-change-fountain', callback

  subscribeToFilePath: (filePath) ->
    @file = new File(filePath)
    @emitter.emit 'did-change-title'
    @handleEvents()
    @renderFountain()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @emitter.emit 'did-change-title' if @editor?  # the if seems redundant
        @handleEvents()
        @renderFountain()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        @parents('.pane').view()?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      @disposables.add atom.packages.onDidActivateInitialPackages(resolve)

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()

    null

  handleEvents: ->
    @disposables.add atom.grammars.onDidAddGrammar => _.debounce((=> @renderFountain()), 250)
    @disposables.add atom.grammars.onDidUpdateGrammar _.debounce((=> @renderFountain()), 250)

    changeHandler = =>
      @renderFountain()
      # TODO: Remove paneForURI call when ::paneForItem is released
      pane = atom.workspace.paneForItem?(this) ? atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    if @file?
      @disposables.add @file.onDidChange(changeHandler)
    else if @editor?
      @disposables.add @editor.onDidChangePath => @emitter.emit 'did-change-title'
      @disposables.add @editor.getBuffer().onDidSave =>
        changeHandler()
      @disposables.add @editor.getBuffer().onDidReload =>
        changeHandler()

  renderFountain: ->
    @showLoading() unless @loaded
    @getFountainSource().then (source) =>
      @renderFountainText(source) if source?

  getFountainSource: ->
    if @file?
      @file.read()
    else if @editor?
      Promise.resolve(@editor.getText())
    else
      Promise.resolve(null)

  getHTML: (callback) ->
    @getFountainSource().then (source) =>
      return unless source?
      renderer.toHTML source, @getPath(), @getGrammar(), callback

  renderFountainText: (text) ->
    fountainParser.parse text, (output) =>
#      html = "<a id='#{ @editorId }' class='pdf-download-button'><span class='icon icon-file-pdf'></span></a>"
      html = ""
      html += "<div class='title-page'>#{output.html.title_page}</div>"
      html += "<div class='page'>#{output.html.script}</div>"

      @loading = false
      @loaded = true
      @html(html)
      @emitter.emit 'did-change-fountain'
      @originalTrigger('fountain:fountain-changed')

      # ensure only one event listener per preview pane
#      $("\##{ @editorId }.pdf-download-button").on 'click', (event) =>
#        fileName = @editor.getTitle()
#        @pdfConverter.initiateConversion(fileName, text)

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "Fountain Preview"

  showLoading: ->
    @loading = true
    @html $$$ ->
      @div class: 'markdown-spinner', 'Loading Markdown\u2026'
