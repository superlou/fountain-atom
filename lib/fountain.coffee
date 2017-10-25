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
      'fountain:toggle-outline-view': => @toggleOutlineView(),
      'fountain:preview-legacy' :=> @preview(),  # deprecated TODO: remove in a later release
      'fountain:preview' :=> @pdfPreview(),
      'fountain:export-PDF' :=> @pdfExport()

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
    if event || activeEditor
      activeEditorPath = activeEditor.getPath()
      if !activeEditorPath
        return atom.notifications.addInfo("File must be saved to render PDF preview")
      projectPath = if event then event.path.replace(/\\/g,'/').split('/') else activeEditorPath.replace(/\\/g,'/').split('/')
      fileName = projectPath.pop()
      text = activeEditor.getSelectedText() || activeEditor.getText()
      pdfConverter = new PdfConverter()
      pdfConverter.createPreview(projectPath.join('/'), fileName, text).then (uri) =>
        atom.workspace.open(uri, {"searchAllPanes":true})
        if !event then activeEditor.onDidSave(this.pdfPreview)
    else
      atom.notifications.addInfo("No fountain file is currently targeted")

  pdfExport: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    if (activeEditor)
      activeEditorPath = activeEditor.getPath()
      if !activeEditorPath
        return atom.notifications.addInfo("File must be saved to export PDF")
      projectPath = activeEditorPath.replace(/\\/g,'/').split('/')
      fileName = projectPath.pop()
      text = activeEditor.getSelectedText() || activeEditor.getText()
      pdfConverter = new PdfConverter()
      pdfConverter.createPdf(projectPath.join('/'), fileName, text).then (uri) ->
        if uri then atom.workspace.open(uri, {"searchAllPanes":true})
    else
      atom.notifications.addInfo("No fountain file is currently targeted")

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
