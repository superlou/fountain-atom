{CompositeDisposable} = require 'atom'
url = require 'url'

FountainSceneListView = null
FountainOutlineView = null
FountainPreviewView = null
renderer = null

createFountainPreviewView = (state) ->
  FountainPreviewView ?= require './fountain-preview-view'
  new FountainPreviewView(state)

isFountainPreviewView = (object) ->
  FountainPreviewView ?= require './fountain-preview-view'
  object instanceof FountainPreviewView

atom.deserializers.add
  name: 'FountainPreviewView'
  deserialize: (state) ->
    createFountainPreviewView(state) if state.constructor is Object


module.exports = Fountain =
  fountainView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with
    # a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'fountain:toggleSceneList': => @toggleSceneList(),
      'fountain:toggleOutlineView': => @toggleOutlineView(),
      'fountain:preview' :=> @preview()

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
    @modalPanel.destroy()
    @subscriptions.dispose()
    @fountainView.destroy()

  #serialize: ->
    #fountainViewState: @fountainView.serialize()

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

  uriForEditor: (editor) ->
    "fountain-preview://editor/#{editor.id}"

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()

    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(uri, options).done (fountainPreviewView) ->
      if isFountainPreviewView(fountainPreviewView)
        previousActivePane.activate()
