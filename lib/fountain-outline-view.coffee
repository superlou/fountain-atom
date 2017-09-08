{CompositeDisposable, Point} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class FountainOutlineView extends ScrollView

  Sortable = require('sortablejs')
  _ = require('underscore')

  panel: null
  outlineLocked: true
  eventHandlers: []

  initialize: (state) ->
    super
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem(@changedPane)

    @editorSubs = new CompositeDisposable

    @attach()

  attach: ->
    @panel ?= atom.workspace.addRightPanel {
      item: this
      visible: false
    }

  @content: ->
    @div class: 'fountain-outline-view', tabindex: -1, =>
      @div class: 'panel-heading', "Fountain Outline", =>
        @span class: 'outline-lock', =>
          @span id: 'outlineLocked', class: 'icon icon-lock'
          @span id: 'outlineUnlocked', class: 'outline-lock-overlay-icon icon icon-remove-close'
      @div class: 'show-scenes-box', =>
        @label for: 'showScenesCheckbox', "Hide Scenes:"
        @input id: 'showScenesCheckbox', type: 'checkbox'
      @div class: 'panel-body', =>
        @ul class: 'outline-list', outlet: "list"

  serialize: ->

  destroy: ->
    @subscriptions.dispose()
    @editorSubs.dispose()
    @element.remove()

  updateList: =>
    text = @editor.getText()
    scenes = @findScenes(text)

    @list.empty()

    starter = '<ul class="outline-ul">'
    tempList =  @formatList(starter, scenes)
    tempList += '</ul>'

    @list.append(tempList)

    sortable = @createSortableList(text, scenes)

    # EVENT HANDLER MANAGEMENT #

    @clearEventHandlers()

    jumpToHandler = $(".outline-item")
      .on 'click', (e) =>
        line = parseInt($(e.currentTarget).attr('data-line'))

        position = new Point(line, -1)
        @editor.scrollToBufferPosition(position)
        @editor.setCursorBufferPosition(position)
        @editor.moveToFirstCharacterOfLine()

    showScenesHandler = $("#showScenesCheckbox")
      .on 'click', (e) ->
        if e.currentTarget.checked
          $('li.scene').hide()
        else
          $('li.scene').show()

    sortable.option("disabled", @outlineLocked)
    @setOutlineLockIconState()
    outlineLockHandler = $(".outline-lock")
      .on 'click', (e) =>
        @outlineLocked = !@outlineLocked
        @setOutlineLockIconState()
        sortable.option("disabled", @outlineLocked);

    @eventHandlers.push(jumpToHandler, showScenesHandler, outlineLockHandler)

  clearEventHandlers: () ->
    _.each(@eventHandlers, (handler) -> handler.off())
    @eventHandlers = []

  setOutlineLockIconState: () =>
    if (@outlineLocked)
        $('.outline-lock-overlay-icon').css("visibility", "hidden");
      else
        $('.outline-lock-overlay-icon').css("visibility", "visible");

  formatList: (formatted, scenes) ->
    for scene, index in scenes
      if scene.type == 'synopsis'
        continue
      formatted += '<li class="outline-item ' + scene.type + ' depth-' + scene.depth + '"'
      formatted += ' data-line="'+ scene.line + '">'
      formatted += '<span class="icon icon-text">' + scene.title + '</span>'

      if scene.hasOwnProperty('children') and scene.children.length > 0
        for child in scene.children
          if child.type == 'synopsis'
            formatted += '<div class="synopsis">' + child.title + '</div>'
            formatted += '</li>'
          else
            formatted += '</li>'
        formatted += @formatList('', scene.children)
      formatted += '</li>'
    formatted

  findScenes: (text) ->
    scenes = []
    ref = text.split('\n')
    scenes = @getNestedChildren([ref, 0, 0])
    scenes = scenes[0]
    scenes

  getNestedChildren: (scenes) ->
    out = []
    arr = scenes[0]
    i = scenes[1]
    depth = scenes[2]
    while i < arr.length
      if arr[i].match(/^#+/)
        matched = arr[i].match(/^(#+)(.+)/)
        if matched[1].length > depth
          nestedKids = @getNestedChildren([arr, i+1, matched[1].length])
          currentScene =
            line: i
            title: matched[2]
            type: "heading" + matched[1].length
            hasNote: false
            children: nestedKids[0]
            depth: depth
          if nestedKids[1] > 0
            i = nestedKids[1]
          out.push currentScene
        else
          break
      else if arr[i].match(/(^EXT\.)|(^INT\.)|(^\.[A-Z]+)|(^\s*=\s*.+)/)
        currentScene =
          line: i
          title: arr[i]
          type: "scene"
          hasNote: false
          depth: depth
        if arr[i].match(/^\s*=\s*/)
          synMatched = arr[i].match(/^\s*=\s*(.+)/)
          currentScene.title = synMatched[1]
          currentScene.type = "synopsis"
        if arr[i].match(/\[\[[^\]]*\]\]/)
          currentScene.hasNote = true
        out.push currentScene
        i++
      else
        i++ #if there is a blank move on
    out = [out,i, depth]
    out


  clearScenes: (text) ->
    @list.innerHTML = ""

  changedPane: (pane) =>
    @editorSubs.dispose()
    if pane and (typeof pane.getText == 'function')
      @editor = pane
      @editorSubs.add @editor.onDidStopChanging(@updateList)
      @updateList()
    else
      @clearScenes()


  # SORTABLE LIST MANAGEMENT #

  createSortableList: (fileText, scenes) =>

    outlineElement = document.getElementsByClassName('outline-ul')[0];
    oldFileLines = fileText.split('\n')
    flatSceneList = @flatten(scenes, [])
    sceneList = _.reject(flatSceneList, _.matches({type: "synopsis"}))

    oldStartLine = null
    oldEndLine = null

    sortable = Sortable.create(outlineElement, {

      onChoose: (evt) =>
        [oldStartLine, oldEndLine] = @getOldLineIndexes(oldFileLines, sceneList, evt)

      onUpdate: (evt) =>
        # scene moved, so generate new file #
        oldIndex = evt.oldIndex
        newIndex = evt.newIndex

        newStartLine = @getNewStartLineIndex(oldFileLines, sceneList, oldIndex, newIndex)

        newFileText = @getNewFileText(oldFileLines, oldStartLine, oldEndLine, newStartLine)

        @setActiveEditorBuffer(newFileText)

        @updateList()

    })
    sortable

  flatten: (structuredScenes, flattenedRep) ->
    i = 0
    while i < structuredScenes.length
      currentScene = structuredScenes[i]
      flattenedRep.push currentScene
      if currentScene.hasOwnProperty('children') and currentScene.children.length > 0
        @flatten(currentScene.children, flattenedRep)
      i++
    flattenedRep

  getOldLineIndexes: (oldFileLines, sceneList, movingElement) =>
    # grab details about scene before array mutates
    sceneCount = sceneList.length
    oldStartLine = parseInt(movingElement.item.attributes[1].value)
    if movingElement.oldIndex == sceneCount - 1
      oldEndLine = oldFileLines.length
    else
      oldEndLine = parseInt(sceneList[movingElement.oldIndex+1].line)
    [oldStartLine, oldEndLine]

  getNewStartLineIndex: (oldFileLines, sceneList, oldIndex, newIndex) =>
    newStartLine = null
    # account for array index changes
    if (newIndex > oldIndex)
      newIndex += 1
    if (sceneList[newIndex])
      newStartLine = parseInt(sceneList[newIndex].line)
    else
      # they can manage any newline gaps
      newStartLine = oldFileLines.length - 1

    # yea, this is an intermediate value
    # because we need slice lengths
    newStartLine

  getNewFileText: (oldFileLines, oldStartLine, oldEndLine, newStartLine) =>

    # isolate relevant chunks
    newFileText = ''
    movingText = oldFileLines.slice(oldStartLine, oldEndLine)
    textBefore = oldFileLines.slice(0, oldStartLine)
    textAfter = oldFileLines.slice(oldEndLine)

    # determine placement of text in preceding or trailing slice
    if newStartLine < textBefore.length
      textBefore.splice.apply(textBefore, [newStartLine, 0].concat(movingText))
    else
      textAfter.splice.apply(textAfter, [newStartLine - textBefore.length - movingText.length, 0].concat(movingText))

    newFileText = textBefore.concat(textAfter).join('\n')
    newFileText

  setActiveEditorBuffer: (newFileText) =>
    if editor = atom.workspace.getActiveTextEditor()
      editor.setText(newFileText)
