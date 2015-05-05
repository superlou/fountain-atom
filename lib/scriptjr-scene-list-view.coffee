{$, CompositeDisposable, Point} = require 'atom'

module.exports =
class ScriptjrSceneListView
  constructor: (serializedState, workspace) ->
    @element = document.createElement('div')
    $(@element).addClass('scriptjr-scene-list')
    @list = document.createElement('ul')
    @element.appendChild(@list)

    @subscriptions = new CompositeDisposable
    @subscriptions.add workspace.onDidChangeActivePaneItem(@changedPane)

    @workspace = workspace

  serialize: ->

  destroy: ->
    @subscriptions.dispose()
    @element.remove()

  getElement: ->
    @element

  updateList: (scenes) ->
    @list.innerHTML = ""

    for scene in scenes
      item = document.createElement('li')
      span = document.createElement('span')
      span.innerHTML = scene.title
      $(span).attr('data-line', scene.line)
      item.appendChild(span)

      @list.appendChild(item)

      $(span).on 'click', (e) =>
        line = $(e.currentTarget).attr('data-line')

        position = new Point(line, -1)
        editor = @workspace.getActiveTextEditor()
        editor.scrollToBufferPosition(position)
        editor.setCursorBufferPosition(position)
        editor.moveToFirstCharacterOfLine()

  findScenes: (text) ->
    scenes = []

    currentScene =
      line: 0
      title: 'TOP'
      hasNote: false

    for line, index in text.split('\n')
      if line.match(/^(EXT)|(INT)|(\^.[A-Z]+)/)
        scenes.push(currentScene)

        currentScene =
          line: index
          title: line
          hasNote: false

      if line.match(/\[\[[^\]]*\]\]/)
        currentScene.hasNote = true

    scenes.push(currentScene)

    @updateList(scenes)

  clearScenes: (text) ->
    @list.innerHTML = ""

  changedPane: (pane) =>
    if pane and (typeof pane.getText == 'function')
      text = pane.getText()
      @findScenes(text)
    else
      @clearScenes()
