{CompositeDisposable, Point} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class FountainOutlineView extends ScrollView

  Sortable = require('sortablejs')
  fs = require('fs')
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

    tempList =  @formatList(scenes)
    @list.append(tempList)

    el = document.getElementsByClassName('outline-ul')[0];

    oldFileLines = text.split('\n')
    sceneList = _.where(scenes, {type: 'scene'} )
    oldStartLine = null
    oldEndLine = null
    sortable = Sortable.create(el, {
      onChoose: (evt) ->
        sceneCount = sceneList.length
        oldStartLine = parseInt(evt.item.attributes[1].value)
        if evt.oldIndex == sceneCount - 1
          oldEndLine = oldFileLines.length
        else
          # assuming exclusive
          oldEndLine = parseInt(sceneList[evt.oldIndex+1].line)

      onUpdate: (evt) =>
        oldIndex = evt.oldIndex
        newIndex = evt.newIndex
        if (oldIndex != newIndex)

          if (newIndex > oldIndex)
            newIndex += 1
          if (sceneList[newIndex])
            newStartLine = parseInt(sceneList[newIndex].line)
          else
            newStartLine = oldFileLines.length - 1

          newFileText = ''

          movingText = oldFileLines.slice(oldStartLine, oldEndLine)

          movingTextLength = oldEndLine - oldStartLine
          textBefore = oldFileLines.slice(0, oldStartLine)
          textAfter = oldFileLines.slice(oldEndLine)

          if newStartLine < textBefore.length
            textBefore.splice.apply(textBefore, [newStartLine, 0].concat(movingText))
          else
            textAfter.splice.apply(textAfter, [newStartLine - textBefore.length - movingTextLength, 0].concat(movingText))

          newFileText = textBefore.concat(textAfter).join('\n')

          dirPath = atom.project.getPaths()[0]
          fs.writeFile(dirPath + "/testConversion.fountain", newFileText, (err)  ->
              if err
                return console.log(err)
              console.log("The file was saved!")
          )

          @updateList()
    });

    @clearEventHandlers()

    #Add the click event handler
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
        console.log("clicked")
        @outlineLocked = !@outlineLocked
        @setOutlineLockIconState()
        sortable.option("disabled", @outlineLocked);

    @eventHandlers.push(jumpToHandler, showScenesHandler, outlineLockHandler)

  formatList: (scenes) ->
    formatted = '<li class="outline-li outline-li "><ul class="outline-ul">'
    for scene, index in scenes
      if scene.type == 'synopsis'
        continue
      formatted += '<li class="outline-item ' + scene.type + '"'
      formatted += ' data-line="'+ scene.line + '">'
      formatted += '<span class="icon icon-text">' + scene.title + '</span>'

      if scene.hasOwnProperty('children') and scene.children.length > 0
        for child in scene.children
          if child.type == 'synopsis'
            formatted += '<div class="synopsis">' + child.title + '</div>'
            formatted += '</li>'
          else
            formatted += '</li>'
        formatted += @formatList(scene.children)
      formatted += '</li>'
    formatted += '</ul></li>'
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

  clearEventHandlers: () ->
    _.each(@eventHandlers, (handler) -> handler.off())
    @eventHandlers = []

  setOutlineLockIconState: () =>
      if (@outlineLocked)
          $('.outline-lock-overlay-icon').css("visibility", "hidden");
        else
          $('.outline-lock-overlay-icon').css("visibility", "visible");