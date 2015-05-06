ScriptjrSceneListView = require './scriptjr-scene-list-view'
{CompositeDisposable} = require 'atom'

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
      'scriptjr-atom:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @scriptjrAtomView.destroy()

  serialize: ->
    scriptjrAtomViewState: @scriptjrAtomView.serialize()

  toggle: ->
    @sceneListView ?= new ScriptjrSceneListView({})

    if @sceneListView.panel.isVisible()
      @sceneListView.panel.hide()
    else
      editor = atom.workspace.getActiveTextEditor()
      @sceneListView.changedPane(editor)
      @sceneListView.panel.show()
