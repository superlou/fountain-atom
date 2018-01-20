FountainOutlineView = require '../lib/fountain-outline-view'
fs = require 'fs'
_ = require 'underscore-plus'
path = require 'path'

describe 'Fountain Outline View Nested Reorder', ->

  beforeEach ->
    # Ensure you're language package is loaded
    waitsForPromise ->
      atom.packages.activatePackage 'fountain'

  # sanity checks
  it 'should have loaded fountain package', ->
    expect(atom.packages.isPackageActive('fountain')).toBeTruthy()

  describe 'generating scene list representations', ->

    @fov
    @fileText
    @fileLines

    beforeEach ->
      @fov = new FountainOutlineView()
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileToRead = path.join(packagePath, 'spec/test_files/outline-view-nested-reorder-tests.fountain')
      @fileText = fs.readFileSync(fileToRead, 'utf8')

    it 'should be able to get scene list', ->
      # this serves as a sanity check for the following tests
      sceneList = @fov.findScenes(@fileText)
      expect(sceneList.length).toBe(4)
      sceneListFlat = []
      @fov.flatten(sceneList, sceneListFlat)
      expect(sceneListFlat.length).toBe(15)

  describe 'getting list (preparation test for the following tests)', ->

    @fov
    @fileText
    @fileLines
    @sceneList
    @sceneListFlat

    beforeEach ->
      @fov = new FountainOutlineView()
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileToRead = path.join(packagePath, 'spec/test_files/outline-view-nested-reorder-tests.fountain')
      @fileText = fs.readFileSync(fileToRead, 'utf8')
      @sceneList = @fov.findScenes(@fileText)
      @sceneListFlat = []
      @fov.flatten(@sceneList, @sceneListFlat)

    it 'should be able to get scene list', ->
      # this serves as a sanity check for the following tests
      sceneList = @fov.findScenes(@fileText)
      expect(sceneList.length).toBe(4)
      sceneListFlattened = []
      @fov.flatten(sceneList, sceneListFlattened)
      expect(sceneListFlattened.length).toBe(15)

  describe 'nested reordering', ->

    @fov
    @editor
    @fileText
    @sceneList
    @sceneListFlat

    beforeEach ->
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileToRead = path.join(packagePath, 'spec/test_files/outline-view-nested-reorder-tests.fountain')
      @fileText = fs.readFileSync(fileToRead, 'utf8')

      # initialize typical view state
      @fov = new FountainOutlineView()
      @fov.initialize()
      @sceneList = @fov.findScenes(@fileText)
      @sceneListFlat = _.reject(@fov.flatten(@sceneList, []), _.matches({type: "synopsis"}))

      # runs the views update logic as well as updated test index refs
      @updateState = () =>
        @fov.updateList()
        @sceneListFlat = _.reject(@fov.flatten(@fov.findScenes(@fov.editor.getText()), []), _.matches({type: "synopsis"}))

      # simulates onChoose call
      @dragScene = (index) =>
        simulatedEvent = {item: {attributes: [null, {value: @sceneListFlat[index].line}, {value: @sceneListFlat[index].endline}]}}
        @fov.onChoose(simulatedEvent)

      # simulates onUpdate call
      @dropScene = (oldIndex, newIndex) =>
        simulatedEvent = {oldIndex: oldIndex, newIndex: newIndex}
        @fov.onUpdate(simulatedEvent)

      # simulates drag/drop of a scene
      @moveScene = (fromIndex, toIndex) =>
        @dragScene(fromIndex)
        @dropScene(fromIndex, toIndex)

      # load up editor
      waitsForPromise =>
        atom.workspace.open(fileToRead, {changeFocus: true}).then (e) =>
          @fov.editor = e
          @fov.outlineLocked = false
          @fov.updateList()

      # load up DOM for sortablejs
      ul = document.createElement('ul')
      ul.className = "outline-ul"
      document.getElementsByTagName('body')[0].appendChild(ul)
      document.getElementsByClassName("outline-ul")[0].appendChild(document.createRange().createContextualFragment(@fov.list))

    it 'should be able to swap siblings', ->
      @moveScene(6, 5)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(6, 5)
      expect(@fov.editor.getText()).toEqual(@fileText)
      @updateState()
      @moveScene(6, 5)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)

    it 'should be able to swap sibling headings', ->
      @updateState()
      @moveScene(8, 2)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(2, 8)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to swap sibling headings with hidden scenes w/o adoption', ->
      @updateState()
      @moveScene(7, 2)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @fov.scenesHidden = true
      @updateState()
      @moveScene(2, 3)
      expect(@fov.editor.getText()).toEqual(@fileText)
      @fov.scenesHidden = false

    it 'should be able to swap top level acts', ->
      @updateState()
      @moveScene(12, 0)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(0, 12)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to adopt/give up children', ->
      @updateState()
      # adopt
      @moveScene(7, 3)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      # give up
      @moveScene(2, 3)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      # to original
      @moveScene(2, 7)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to have children move under sibling', ->
      @updateState()
      @moveScene(6, 7)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(7, 6)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to have children move under parent', ->
      @updateState()
      @moveScene(6, 2)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(2, 6)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to have children move under grandparent', ->
      @updateState()
      @moveScene(3, 1)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(1, 3)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move heading between acts', ->
      @updateState()
      @moveScene(1, 11)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(4, 1)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move sub-heading between headings', ->
      @updateState()
      @moveScene(2, 9)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(5, 2)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move scene element to first position', ->
      @updateState()
      @moveScene(6, 13)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(13, 6)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move scene element to final position', ->
      @updateState()
      @moveScene(6, 13)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(13, 6)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move empty heading element to first position', ->
      @updateState()
      @moveScene(7, 0)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(0, 7)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move empty heading element to final position', ->
      @updateState()
      @moveScene(7, 13)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(13, 7)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move populated heading element to first position', ->
      @updateState()
      @moveScene(2, 0)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(0, 6)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to move populated heading element to final position', ->
      @updateState()
      @moveScene(2, 13)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(9, 2)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should NOT be able to move parent into self', ->
      @updateState()
      @moveScene(2, 4)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should NOT be able to move parent under child', ->
      @updateState()
      @moveScene(1, 4)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should NOT be able to move parent under grandchild', ->
      @updateState()
      @moveScene(0, 4)
      expect(@fov.editor.getText()).toEqual(@fileText)


