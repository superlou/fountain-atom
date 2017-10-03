{CompositeDisposable} = require 'atom'
url = require 'url'
PdfConverter = require './fountain-pdf-converter.coffee'

FountainOutlineView = null
FountainPreviewView = null
renderer = null

createFountainPreviewView = (state) ->
  FountainPreviewView ?= require './fountain-preview-view'
  new FountainPreviewView(state)

isFountainPreviewView = (object) ->
  FountainPreviewView ?= require './fountain-preview-view'
  object instanceof FountainPreviewView

module.exports = Fountain =
  subscriptions: null

  activate: (state) ->

    require('atom-package-deps').install('fountain', true)

    # Events subscribed to in atom's system can be easily cleaned up with
    # a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'fountain:toggleOutlineView': => @toggleOutlineView(),
      'fountain:preview' :=> @preview(),
      'fountain:pdfPreview' :=> @pdfPreview(),
      'fountain:pdfExport' :=> @pdfExport()

    if state.outlineViewIsVisible
      @toggleOutlineView()

    atom.workspace.addOpener (uri) ->
      try
        {protocol, host, pathname} = url.parse(uri)
      catch error
        return

      return unless protocol is 'fountain-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createFountainPreviewView(editorId: pathname.substring(1))
      else
        createFountainPreviewView(filePath: pathname)

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    outlineViewIsVisible: @outlineView && @outlineView.panel.isVisible()

  deserializeFountainPreviewView: (state) ->
    createFountainPreviewView(state) if state.constructor is Object

  toggleOutlineView: ->
    FountainOutlineView ?= require './fountain-outline-view'
    @outlineView ?= new FountainOutlineView({})

    if @outlineView.panel.isVisible()
      @outlineView.panel.hide()
    else
      editor = atom.workspace.getActiveTextEditor()
      @outlineView.changedPane(editor)
      @outlineView.panel.show()

  preview: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    return unless editor.getGrammar().scopeName == 'source.fountain'
    @addPreviewForEditor(editor)

  pdfPreview: (event) ->
    activeEditor = atom.workspace.getActiveTextEditor()
    projectPath = if event then event.path.split('/') else activeEditor.getPath().split('/')
    fileName = projectPath.pop()
    text = activeEditor.getSelectedText() || activeEditor.getText()
    pdfConverter = new PdfConverter()
    uri = pdfConverter.createPreview(projectPath.join('/'), fileName, text)
    atom.workspace.open(uri, {"searchAllPanes":true})
    if !event then activeEditor.onDidSave(this.pdfPreview)

  pdfExport: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    projectPath = activeEditor.getPath().split('/')
    fileName = projectPath.pop()
    text = activeEditor.getSelectedText() || activeEditor.getText()
    pdfConverter = new PdfConverter()
    uri = pdfConverter.createPdf(projectPath.join('/'), fileName, text)
    if uri then atom.workspace.open(uri, {"searchAllPanes":true})

  uriForEditor: (editor) ->
    "fountain-preview://editor/#{editor.id}"

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()

    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(uri, options).then (fountainPreviewView) ->
      if isFountainPreviewView(fountainPreviewView)
        previousActivePane.activate()
