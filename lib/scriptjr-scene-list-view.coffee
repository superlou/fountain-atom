{CompositeDisposable, Point} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class ScriptjrSceneListView extends ScrollView
  panel: null

  initialize: (state) ->
    super
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem(@changedPane)

    @attach()

  attach: ->
    @panel ?= atom.workspace.addRightPanel {
      item: this
      visible: false
    }

  @content: ->
    @div class: 'scriptjr-scene-list', tabindex: -1, =>
      @div class: 'panel-heading', "Fountain Scene List"
      @div class: 'panel-body padded', =>
        @ul class: 'list-group', outlet: "list"

  serialize: ->

  destroy: ->
    @subscriptions.dispose()
    @element.remove()

  updateList: (text) ->
    scenes = @findScenes(text)

    @list.empty()

    for scene in scenes
      $('<li data-line="'+ scene.line + '"></li>')
        .append('<span class="icon icon-book">' + scene.title + '</span>')
        .addClass('list-item')
        .appendTo(@list)
        .on 'click', (e) =>
          line = $(e.currentTarget).attr('data-line')

          position = new Point(line, -1)
          editor = atom.workspace.getActiveTextEditor()
          editor.scrollToBufferPosition(position)
          editor.setCursorBufferPosition(position)
          editor.moveToFirstCharacterOfLine()

  findScenes: (text) ->
    scenes = []

    currentScene =
      line:     0
      title:    'TOP'
      hasNote:  false

    for line, index in text.split('\n')
      if line.match(/^(EXT)|(INT)|(\^.[A-Z]+)/)
        scenes.push currentScene

        currentScene =
          line: index
          title: line
          hasNote: false

      if line.match(/\[\[[^\]]*\]\]/)
        currentScene.hasNote = true

    scenes.push(currentScene)
    scenes

  clearScenes: (text) ->
    @list.innerHTML = ""

  changedPane: (pane) =>
    if pane and (typeof pane.getText == 'function')
      text = pane.getText()
      @updateList(text)
    else
      @clearScenes()
