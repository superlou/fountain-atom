{CompositeDisposable, Point, Emitter} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class FountainOutlineView extends ScrollView

  Sortable = require('sortablejs')
  _ = require('underscore-plus')

  outlineLocked: true
  eventHandlers: []

  initialize: (serializedState) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem(@changedActiveItem)
    @editorSubs = new CompositeDisposable
    @emitter = new Emitter

  attached: ->
    @subscriptions.add atom.tooltips.add(@find('#scenes_visible_button'), {
      title: 'Include scenes'}
    )
    @subscriptions.add atom.tooltips.add(@find('#draggable_button'), {
      title: 'Enable outline dragging'
    })

  destroy: ->
    @emitter.emit 'closed-outline-view'
    @clearEventHandlers()
    @subscriptions.dispose()
    @editorSubs.dispose()
    @element.remove()

  getTitle: ->
    'Fountain Outline'

  getDefaultLocation: ->
    'right'

  getURI: ->
    'atom://fountain-outline'

  getElement: ->
    @element

  @content: ->
    @div class: 'fountain-outline-view', tabindex: -1, =>
      @div class: 'block controls', =>
        @div class: 'btn-group', =>
          @button class: 'btn', id: 'scenes_visible_button', "Scenes"
          @button class: 'btn', id: 'draggable_button', "Draggable"
        @button class: 'btn icon icon-file-pdf pdf-download-button', 'PDF'
      @div class: 'outline block', =>
        @ul class: 'outline-list', outlet: "list"

  serialize: ->

  updateList: =>
    text = @editor.getText()
    scenes = @findScenes(text)

    @list.empty()

    starter = '<ul class="outline-ul">'
    tempList =  @formatList(starter, scenes)
    tempList += '</ul>'

    @list.append(tempList)

    # if we haven't lost track of the file, continue
    #  else clear out the list contents
    if (document.getElementsByClassName('outline-ul')[0])

      sortable = @createSortableList(text, scenes)

      # EVENT HANDLER MANAGEMENT #
      @clearEventHandlers()

      jumpToHandler = $(".outline-item").on 'click', (e) =>
          line = parseInt($(e.currentTarget).attr('data-line'))
          position = new Point(line, -1)
          @editor.scrollToBufferPosition(position)
          @editor.setCursorBufferPosition(position)
          @editor.moveToFirstCharacterOfLine()

      @scenesHidden ||= false
      @setScenesHidden(@scenesHidden)
      showScenesHandler = $("#scenes_visible_button").on 'click', (e) =>
          @scenesHidden = !@scenesHidden
          @setScenesHidden(@scenesHidden)

      @setOutlineLocked(@outlineLocked, sortable)
      outlineLockHandler = $("#draggable_button").on 'click', (e) =>
          @outlineLocked = !@outlineLocked
          @setOutlineLocked(@outlineLocked, sortable)

      downloadHandler = $(".pdf-download-button").on 'click', (e) =>
        if @editor?
          atom.packages.getActivePackage('fountain').mainModule.pdfExport(@editor);

      @eventHandlers.push(jumpToHandler, showScenesHandler, outlineLockHandler, downloadHandler)

    else
      @list.empty()

  clearEventHandlers: () ->
    _.each(@eventHandlers, (handler) -> handler.off())
    @eventHandlers = []

  setScenesHidden: (hidden) =>
    $('li.scene').toggle(!hidden)
    $('#scenes_visible_button').toggleClass('selected', !hidden)

  setOutlineLocked: (locked, sortable) =>
    sortable.option("disabled", locked);
    $('#draggable_button').toggleClass('selected', !locked)

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
      section = arr[i].match(/^#+/)
      if section
        matched = arr[i].match(/^(#+)(.+)/)
        if section[0].length > depth
          nestedKids = @getNestedChildren([arr, i+1, section[0].length])
          matchedTitleText = if matched then matched[2].trim() else ""
          hasTitle = matched && matchedTitleText && matchedTitleText != "#"
          currentScene =
            line: i
            title: if hasTitle then matched[2] else "(untitled section)"
            type: "heading" + section[0].length
            hasNote: false
            children: nestedKids[0]
            depth: depth
          if nestedKids[1] > 0
            i = nestedKids[1]
          out.push currentScene
        else
          break
      else if arr[i].match(/(^EXT\.)|(^INT\.)|(^\.[A-Z]+)|(^\s*=\s*.+)/)
        # Remove leading period if forcing a scene
        if arr[i][0] == "."
          arr[i] = arr[i].substr(1)

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

  clearScenes: () ->
    @list.empty()

  changedActiveItem: (item) =>
    grammarId = item?.getGrammar?().id

    if grammarId == 'source.fountain'
      @editor = item
      @editorSubs.dispose()
      @editorSubs.add @editor.onDidStopChanging(@updateList)
      @updateList()

  # SORTABLE LIST MANAGEMENT #

  createSortableList: (fileText, scenes) =>
    outlineElement = document.getElementsByClassName('outline-ul')[0];
    oldFileLines = fileText.split('\n')
    flatSceneList = @flatten(scenes, [])
    sceneList = _.reject(flatSceneList, _.matches({type: "synopsis"}))

    oldStartLine = null
    oldEndLine = null

    @onChoose = (evt) =>
#      console.debug("onChoose", evt.oldIndex)
      [oldStartLine, oldEndLine] = @getOldLineIndexes(oldFileLines, sceneList, evt)

    @onUpdate = (evt) =>
#      console.debug("onUpdate", evt.oldIndex, evt.newIndex)
      oldIndex = evt.oldIndex
      newIndex = evt.newIndex
      newLineFallsWithinOwnBounds = sceneList[newIndex].line > sceneList[oldIndex].line && sceneList[newIndex].line < sceneList[oldIndex].endline
      if (!newLineFallsWithinOwnBounds)
        # element moved, so generate new buffer contents #
        newStartLine = @getNewStartLineIndex(oldFileLines, sceneList, oldIndex, newIndex)
        newFileText = @getNewFileText(oldFileLines, oldStartLine, oldEndLine, newStartLine)
        @editor?.setText(newFileText)
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
#    console.debug("getOldIndexLines", oldStartLine, oldEndLine)
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
