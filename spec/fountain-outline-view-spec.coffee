FountainOutlineView = require '../lib/fountain-outline-view'
fs = require 'fs'
_ = require 'underscore'

describe 'Fountain Outline View', ->
  
  SCENE_LIST = [ { line : 12, title : "EXT. BRICK'S PATIO - DAY", type : "scene", hasNote : false }, { line : 52, title : "INT. TRAILER HOME - DAY", type : "scene", hasNote : false }, { line : 69, title : "EXT. BRICK'S POOL - DAY", type : "scene", hasNote : false }, { line : 80, title : ".SNIPER SCOPE POV", type : "scene", hasNote : false }, { line : 95, title : ".OPENING TITLES", type : "scene", hasNote : false }, { line : 105, title : "EXT. WOODEN SHACK - DAY", type : "scene", hasNote : false }, { line : 129, title : "INT. GARAGE - DAY", type : "scene", hasNote : false }, { line : 144, title : "EXT. PALATIAL MANSION - DAY", type : "scene", hasNote : false } ]
  FORMATTED_SCENE_LIST = '<li class="outline-li outline-li "><ul class="outline-ul"><li class="outline-item scene" data-line="12"><span class="icon icon-text">EXT. BRICK\'S PATIO - DAY</span></li><li class="outline-item scene" data-line="52"><span class="icon icon-text">INT. TRAILER HOME - DAY</span></li><li class="outline-item scene" data-line="69"><span class="icon icon-text">EXT. BRICK\'S POOL - DAY</span></li><li class="outline-item scene" data-line="80"><span class="icon icon-text">.SNIPER SCOPE POV</span></li><li class="outline-item scene" data-line="95"><span class="icon icon-text">.OPENING TITLES</span></li><li class="outline-item scene" data-line="105"><span class="icon icon-text">EXT. WOODEN SHACK - DAY</span></li><li class="outline-item scene" data-line="129"><span class="icon icon-text">INT. GARAGE - DAY</span></li><li class="outline-item scene" data-line="144"><span class="icon icon-text">EXT. PALATIAL MANSION - DAY</span></li></ul></li>'
  SCENE_TYPE_LIST = _.where(SCENE_LIST, {type: 'scene'} )

  beforeEach ->
    # Ensure you're language package is loaded
    waitsForPromise ->
      atom.packages.activatePackage 'fountain'

  # sanity checks
  it 'should have loaded fountain package', ->
    expect(atom.packages.isPackageActive('fountain')).toBeTruthy()


  describe 'formatting', ->

    @fov
    @fileText

    beforeEach ->
      @fov = new FountainOutlineView()
      fileToRead = 'spec/outline-view-tests.fountain'
      @fileText = fs.readFileSync(fileToRead, 'utf8')

    it 'should have text', ->
      expect(@fileText).toBeTruthy()

    it 'should have FOV object', ->
      expect(@fov).toBeDefined()

    it 'should find expected scenes', ->
      expect(@fov.findScenes(@fileText)).toEqual(SCENE_LIST)

    it 'should generate expected html', ->
      expect(@fov.formatList(SCENE_LIST)).toEqual(FORMATTED_SCENE_LIST)


  describe 'reordering', ->

    @fov
    @fileText
    @fileLines

    beforeEach ->
      @fov = new FountainOutlineView()
      fileToRead = 'spec/outline-view-tests.fountain'
      @fileText = fs.readFileSync(fileToRead, 'utf8')
      @fileLines = @fileText.split('\n')

    it 'should be able to get oldLineIndexes', ->
      # mocking first scene initial drag event
      mockedMovingElement = {oldIndex: 0, newIndex: undefined, item: attributes: [null, {value: "12"}, null]}
      [startLine, endLine] = @fov.getOldLineIndexes(@fileLines, SCENE_TYPE_LIST, mockedMovingElement)
      expect(startLine).toEqual(12)
      expect(endLine).toEqual(52)

    it 'should be able to get oldLineIndexes for last scene', ->
      # mocking first scene initial drag event
      linesInFile = 161
      mockedMovingElement = {oldIndex: 7, newIndex: undefined, item: attributes: [null, {value: "144"}, null]}
      [startLine, endLine] = @fov.getOldLineIndexes(@fileLines, SCENE_TYPE_LIST, mockedMovingElement)
      expect(startLine).toEqual(144)
      expect(endLine).toEqual(linesInFile)

    it 'should be able to get newStartLineIndex before current', ->
      startLine = @fov.getNewStartLineIndex(@fileLines, SCENE_TYPE_LIST, 5, 3)
      expect(startLine).toEqual(80)

    it 'should be able to get newStartLineIndex after current', ->
      startLine = @fov.getNewStartLineIndex(@fileLines, SCENE_TYPE_LIST, 3, 5)
      # this index is grabbed before the index shift is calculated
      expect(startLine).toEqual(129)

    it 'should be able to get newStartLineIndex at last index', ->
      lastIndexInFileArray = 160
      startLine = @fov.getNewStartLineIndex(@fileLines, SCENE_TYPE_LIST, 5, 7)
      expect(startLine).toEqual(lastIndexInFileArray)

    it 'should be able to swap from beginning and keep same number of lines', ->
      # swap 0 to 1
      newText = @fov.getNewFileText(@fileLines, 12, 52, 69)
      expect(newText.split('\n').length).toEqual(@fileLines.length)

    it 'should be able to swap from end and keep same number of lines', ->
      # swap 7 to 6
      newText = @fov.getNewFileText(@fileLines, 144, @fileLines.length, 129)
      expect(newText.split('\n').length).toEqual(@fileLines.length)

    it 'should be able to swap from middle and keep same number of lines', ->
      # swap 2 to 6
      newText = @fov.getNewFileText(@fileLines, 69, 80, 144)
      expect(newText.split('\n').length).toEqual(@fileLines.length)

    it 'should be able to swap from beginning to end and keep same number of lines', ->
      # swap 0 to 7
      newText = @fov.getNewFileText(@fileLines, 12, 52, @fileLines.length)
      expect(newText.split('\n').length).toEqual(@fileLines.length)

    it 'should have the same text after a swap back', ->
      # swap 0 to 1
      newText = @fov.getNewFileText(@fileLines, 12, 52, 69)
      # swap 1 to 0
      originalText = @fov.getNewFileText(newText.split('\n'), 29, 69, 12)
      expect(originalText.split('\n').length).toEqual(@fileLines.length)
      expect(originalText).toEqual(@fileText)

    it 'should have the same text after several swaps', ->
      # swap 7 to 0
      newText = @fov.getNewFileText(@fileLines, 144, 161, 12)

      # swap 3 to 7
      newText = @fov.getNewFileText(newText.split('\n'), 86, 97, 160)

      # swap 1 to 3
      newText = @fov.getNewFileText(newText.split('\n'), 29, 69, 101)

      # swap 3 to 1
      newText = @fov.getNewFileText(newText.split('\n'), 61, 101, 29)

      # swap 7 to 3
      newText = @fov.getNewFileText(newText.split('\n'), 149, 160, 86)

      # swap 0 to 7
      originalText = @fov.getNewFileText(newText.split('\n'), 12, 29, 161)
      expect(originalText.split('\n').length).toEqual(@fileLines.length)
      expect(originalText).toEqual(@fileText)