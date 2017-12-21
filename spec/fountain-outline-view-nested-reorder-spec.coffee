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

  describe 'sibling and parent reordering', ->

    @fov
    @editor
    @fileText
    @sceneList
    @sceneListFlat

    beforeEach ->
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileToRead = path.join(packagePath, 'spec/test_files/outline-view-nested-reorder-tests.fountain')
      @fileText = fs.readFileSync(fileToRead, 'utf8')

      @fov = new FountainOutlineView()
      @fov.initialize()
      @sceneList = @fov.findScenes(@fileText)
      @sceneListFlat = []
      @fov.flatten(@sceneList, @sceneListFlat)

      # runs the views update logic as well as updated test index refs
      @updateState = () =>
        @fov.updateList()
        @sceneListFlat = @fov.flatten(@fov.findScenes(@fov.editor.getText()), [])

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

      waitsForPromise =>
        atom.workspace.open(fileToRead, {changeFocus: true}).then (e) =>
          @fov.editor = e
          @fov.outlineLocked = false
          @fov.updateList()

      ul = document.createElement('ul')
      ul.className = "outline-ul"
      document.getElementsByTagName('body')[0].appendChild(ul)
      document.getElementsByClassName("outline-ul")[0].appendChild(document.createRange().createContextualFragment(@fov.list))

    it 'should be able to swap siblings', ->
      @moveScene(6, 4)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(6, 4)
      expect(@fov.editor.getText()).toEqual(@fileText)
      @updateState()
      @moveScene(6, 4)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)

    it 'should be able to swap sibling headings', ->
      @updateState()
      @moveScene(8, 2)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(4, 2)
      expect(@fov.editor.getText()).toEqual(@fileText)

    it 'should be able to swap sibling headings with hidden scenes', ->
      @updateState()
      @moveScene(8, 2)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @fov.scenesHidden = true
      @updateState()
      @moveScene(4, 2)
      expect(@fov.editor.getText()).toEqual(@fileText)
      @fov.scenesHidden = false

    it 'should be able to swap top level acts', ->
      @updateState()
      @moveScene(12, 0)
      expect(@fov.editor.getText()).not.toEqual(@fileText)
      expect(@fov.editor.getText().length).toEqual(@fileText.length)
      @updateState()
      @moveScene(0, 11)
      expect(@fov.editor.getText()).toEqual(@fileText)

