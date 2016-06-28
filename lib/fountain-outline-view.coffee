{CompositeDisposable, Point} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class FountainOutlineView extends ScrollView
  panel: null

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
      @div class: 'panel-heading', "Fountain Outline"
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

    #Add the click event handler
    $(".outline-item")
      .on 'click', (e) =>
        line = parseInt($(e.currentTarget).attr('data-line'))

        position = new Point(line, -1)
        @editor.scrollToBufferPosition(position)
        @editor.setCursorBufferPosition(position)
        @editor.moveToFirstCharacterOfLine()

    $("#showScenesCheckbox")
      .on 'click', (e) ->
        if e.currentTarget.checked
          $('li.scene').hide()
        else
          $('li.scene').show()

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
