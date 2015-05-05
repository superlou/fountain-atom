ScriptjrAtomView = require './scriptjr-atom-view'
ScriptjrSceneListView = require './scriptjr-scene-list-view'
{CompositeDisposable} = require 'atom'

module.exports = ScriptjrAtom =
  scriptjrAtomView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @sceneListView = new ScriptjrSceneListView({}, atom.workspace)
    @sceneListPanel = atom.workspace.addRightPanel {
      item: @sceneListView.getElement()
      visible: false
    }

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
    console.log 'ScriptjrAtom was toggled!'

    if @sceneListPanel.isVisible()
      @sceneListPanel.hide()
    else
      editor = atom.workspace.getActiveTextEditor()

      if editor and (typeof editor.getText == 'function')
        @sceneListView.findScenes(editor.getText())
      else
        @sceneListView.clearScenes()

      @sceneListPanel.show()
