{CompositeDisposable, Point} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class FountainOutlineView extends ScrollView

  Sortable = require('sortablejs')
  _ = require('underscore-plus')

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
      @div class: 'panel-heading', =>
        @a class: 'outline-lock', =>
          @span id: 'outlineLock', class: 'icon icon-lock'
          @span id: 'outlineUnlocked', class: 'outline-lock-overlay-icon icon icon-remove-close'
        @div class: 'panel-heading-text', "Fountain Outline"
        @a class: 'pdf-download-button', =>
          @span id: 'pdfDownload', class: 'icon icon-file-pdf'
        @div class: 'show-scenes-box', =>
          @label for: 'showScenesCheckbox', "Hide Scenes:"
          @input id: 'showScenesCheckbox', type: 'checkbox'
      @div class: 'panel-body', =>
        @ul class: 'outline-list', outlet: "list"

  serialize: ->

  destroy: ->
    @clearEventHandlers()
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

    @scenesHidden ||= false
    @setSceneHiddenState()
    showScenesHandler = $("#showScenesCheckbox")
      .on 'click', (e) =>
        if e.currentTarget.checked
          @scenesHidden = true
        else
          @scenesHidden = false
        @setSceneHiddenState()

    sortable.option("disabled", @outlineLocked)
    @setOutlineLockIconState()
    outlineLockHandler = $(".outline-lock")
      .on 'click', (e) =>
        @outlineLocked = !@outlineLocked
        @setOutlineLockIconState()
        sortable.option("disabled", @outlineLocked);

    downloadHandler = $(".pdf-download-button")
      .on 'click', (e) =>
        atom.packages.getActivePackage('fountain').mainModule.pdfExport();

    @eventHandlers.push(jumpToHandler, showScenesHandler, outlineLockHandler, downloadHandler)

  clearEventHandlers: () ->
    _.each(@eventHandlers, (handler) -> handler.off())
    @eventHandlers = []

  setSceneHiddenState: () =>
    if (@scenesHidden)
      $('li.scene').hide()
    else
      $('li.scene').show()

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
      formatted += ' data-line="'+ scene.line + '" end-line="'+ scene.endline + '">'
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
    @setEndlines(scenes, null, ref.length)
    scenes

  setEndlines: (scenes, nextParentSiblingLine, totalLineCount) ->
    nextParentSiblingLine ||= totalLineCount
    i = 0
    while i < scenes.length
      nextSiblingLine

      # supports drag drop when scenes hidden
      scenes[i].parentEndline = nextParentSiblingLine

      # last element
      if i == scenes.length - 1
        nextSiblingLine = nextParentSiblingLine
        scenes[i].endline = nextParentSiblingLine
        
      # all other elements can use the next index
      else
        nextSiblingLine  = scenes[i+1].line
        scenes[i].endline = scenes[i+1].line

      #process children
      if scenes[i].children
        @setEndlines(scenes[i].children, nextSiblingLine)

      i++

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

    @onChoose = (evt) =>
      [oldStartLine, oldEndLine] = @getOldLineIndexes(oldFileLines, sceneList, evt)

    @onUpdate = (evt) =>
      oldIndex = evt.oldIndex
      newIndex = evt.newIndex
      newLineFallsWithinOwnBounds = sceneList[newIndex].line > sceneList[oldIndex].line && sceneList[newIndex].line < sceneList[oldIndex].endline
      if (!newLineFallsWithinOwnBounds)
        # element moved, so generate new buffer contents #
        newStartLine = @getNewStartLineIndex(oldFileLines, sceneList, oldIndex, newIndex)
        newFileText = @getNewFileText(oldFileLines, oldStartLine, oldEndLine, newStartLine)
        @setActiveEditorBuffer(newFileText)
      else
        # update view manually since nothing changed
        @updateList()

    sortable = Sortable.create(outlineElement, {
      onChoose: @onChoose
      onUpdate: @onUpdate
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
    oldStartLine = parseInt(movingElement.item.attributes[1].value)
    oldEndLine = parseInt(movingElement.item.attributes[2].value)
    [oldStartLine, oldEndLine]

  getNewStartLineIndex: (oldFileLines, sceneList, oldIndex, newIndex) =>
    newStartLine = null

    # account for array index changes
    if (newIndex > oldIndex)
      newIndex += 1

    # if not the last array position
    if (sceneList[newIndex])

      if (@scenesHidden)

        targetIndexIsScene = sceneList[newIndex].type == 'scene'
        targetIsFirstChild = !sceneList[newIndex-1] || (sceneList[newIndex-1].endline == sceneList[newIndex].parentEndline)

        if (!targetIndexIsScene && targetIsFirstChild)
          newStartLine = parseInt(sceneList[newIndex].line)
        else
          # index to the parent to place after all children
          newStartLine = parseInt(sceneList[newIndex-1].endline)

      else
        newStartLine = parseInt(sceneList[newIndex].line)

    else

      # if has preceding sibling
      if (sceneList[newIndex - 1])
        newStartLine = sceneList[newIndex - 1].endline
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
      @editor = editor
      @editor.setText(newFileText)