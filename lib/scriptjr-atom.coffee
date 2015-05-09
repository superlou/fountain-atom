ScriptjrSceneListView = require './scriptjr-scene-list-view'
{CompositeDisposable} = require 'atom'
url = require 'url'

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


module.exports = ScriptjrAtom =
  scriptjrAtomView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with
    # a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'scriptjr-atom:toggleSceneList': => @toggleSceneList(),
      'scriptjr-atom:preview' :=> @preview()

    atom.workspace.addOpener (uri) ->
      try
        {protocol, host, pathname} = url.parse(uri)
      catch error
        return

      return unless protocol is 'scriptjr-atom-preview:'

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
    @scriptjrAtomView.destroy()

  serialize: ->
    scriptjrAtomViewState: @scriptjrAtomView.serialize()

  toggleSceneList: ->
    @sceneListView ?= new ScriptjrSceneListView({})

    if @sceneListView.panel.isVisible()
      @sceneListView.panel.hide()
    else
      editor = atom.workspace.getActiveTextEditor()
      @sceneListView.changedPane(editor)
      @sceneListView.panel.show()

  preview: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    return unless editor.getGrammar().scopeName == 'source.fountain'
    @addPreviewForEditor(editor)

  uriForEditor: (editor) ->
    "scriptjr-atom-preview://editor/#{editor.id}"

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()

    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(uri, options).done (fountainPreviewView) ->
      if isFountainPreviewView(fountainPreviewView)
        previousActivePane.activate()
