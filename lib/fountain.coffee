{CompositeDisposable, Disposable} = require 'atom'
url = require 'url'
PdfConverter = require './fountain-pdf-converter.coffee'

FountainPreviewView = null
FountainOutlineView = null
renderer = null

createFountainPreviewView = (state) ->
  FountainPreviewView ?= require './fountain-preview-view'
  new FountainPreviewView(state)

isFountainPreviewView = (object) ->
  FountainPreviewView ?= require './fountain-preview-view'
  object instanceof FountainPreviewView

createFountainOutlineView = () ->
  FountainOutlineView ?= require './fountain-outline-view.coffee'
  new FountainOutlineView();

module.exports = Fountain =

  config:
    settings1:
      title: 'General'
      type: 'object'
      properties:
        print_title_page:
          type: 'boolean'
          default: true
          title: 'Print title page'
          description: 'Whether title page should be included in pdf'
        show_page_numbers:
          type: 'boolean'
          default: true
          title: 'Show page numbers'
          description: 'Whether page numbers will be rendered on each page'
        print_profile:
          type: 'string'
          enum: ['a4', 'usletter']
          default: 'usletter'
          title: 'Print profile'
          description: 'Specify the size of paper for printing pdf'
    settings2:
      title: 'Text'
      type: 'object'
      properties:
        embolden_scene_headers:
          type: 'boolean'
          default: true
          title: 'Embolden scene headers'
          description: 'Whether scene headers will be rendered in bold font'
        print_sections:
          type: 'boolean'
          default: true
          title: 'Print sections'
          description: 'Whether to render sections in pdf (marked with #)'
        print_synopsis:
          type: 'boolean'
          default: true
          title: 'Print synopses'
          description: 'Whether to render synopses in pdf (marked with =)'
        print_actions:
          type: 'boolean'
          default: true
          title: 'Print actions'
          description: 'Whether to render action blocks in pdf'
        print_headers:
          type: 'boolean'
          default: true
          title: 'Print headers'
          description: 'Whether to render scene headers in pdf'
        print_dialogues:
          type: 'boolean'
          default: true
          title: 'Print dialogues'
          description: 'Whether to render dialogues in pdf'
        print_notes:
          type: 'boolean'
          default: false
          title: 'Print notes'
          description: 'Whether to render notes in pdf'
    settings3:
      title: 'Numbering'
      type: 'object'
      properties:
        number_sections:
          type: 'boolean'
          default: false
          title: 'Number sections'
          description: 'Whether to auto-number sections in pdf'
        scenes_numbers:
          type: 'string'
          enum: ['none', 'left', 'right', 'both']
          default: 'none'
          title: 'Scene numbers'
          description: 'Specify position of scene auto-numbering in pdf'
    settings4:
      title: 'Spacing'
      type: 'object'
      properties:
        use_dual_dialogue:
          type: 'boolean'
          default: false
          title: 'Dual dialogue'
          description: 'Whether concurrent dialogue should be shown side by side'
        each_scene_on_new_page:
          type: 'boolean'
          default: false
          title: 'Each scene on new page'
          description: 'Whether to show each scene on new page in pdf'
        split_dialogue:
          type: 'boolean'
          default: false
          title: 'Split dialogue'
          description: 'Whether to split dialogue between pages or not in pdf'
        double_space_between_scenes:
          type: 'boolean'
          default: true
          title: 'Double space between scenes'
          description: 'Whether a double space should be inserted between scenes in pdf'
    settings5:
      title: 'Custom'
      type: 'object'
      properties:
        font_family:
          type: 'string'
          enum: ['AnonymousPro','CourierCode','CourierPrime','GNUTypewriter']
          default: 'CourierPrime'
          title: 'Font Family'
          description: 'Font to be used in rendering pdf'
        print_header:
          type: 'string'
          default: ''
          title: 'Header'
          description: 'A text to put on the top of the page'
        print_footer:
          type: 'string'
          default: ''
          title: 'Footer'
          description: 'A text to put on the bottom of the page'
        print_watermark:
          type: 'string'
          default: ''
          title: 'Watermark'
          description: 'Watermark text to be shown on the page'

  subscriptions: null

  activate: (state) ->
    require('atom-package-deps').install('fountain', true)

    # Events subscribed to in atom's system can be easily cleaned up with
    # a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Add an opener, command, and diposable for the test view
    @subscriptions.add atom.workspace.addOpener (uri) ->
      if uri == 'atom://fountain-outline'
        return createFountainOutlineView();

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'fountain:toggle-outline-view': => @toggleOutlineView(),
      'fountain:preview-legacy' :=> @preview(),  # deprecated TODO: remove in a later release
      'fountain:preview' :=> @pdfPreview(),
      'fountain:export-PDF' :=> @pdfExport()

    atom.workspace.addOpener (uri) ->
      try
        {protocol, host, pathname} = url.parse(uri)
      catch error
        return

      return unless protocol is 'fountain-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createFountainPreviewView(editorId: pathname.substring(1))
      else
        createFountainPreviewView(filePath: pathname)

  toggleOutlineView: ->
    atom.workspace.toggle('atom://fountain-outline')

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {}

  deserializeFountainPreviewView: (state) ->
    createFountainPreviewView(state) if state.constructor is Object

  preview: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    return unless editor.getGrammar().scopeName == 'source.fountain'
    @addPreviewForEditor(editor)

  editorOrActiveEditor: (editor) ->
    if editor? then editor else atom.workspace.getActiveTextEditor()

  pdfPreview: (event) ->
    activeEditor = atom.workspace.getActiveTextEditor()
    unless activeEditor.getGrammar().scopeName == 'source.fountain'
      atom.notifications.addInfo("No fountain file is currently targeted")
      return

    if event || activeEditor
      activeEditorPath = activeEditor.getPath()
      if !activeEditorPath
        return atom.notifications.addInfo("File must be saved to render PDF preview")
      text = activeEditor.getSelectedText() || activeEditor.getText()
      pdfConverter = new PdfConverter()
      pdfConverter.createPreview((if event then event.path else activeEditorPath), text).then (uri) =>
        atom.workspace.open(uri, {searchAllPanes:true})
    else
      atom.notifications.addInfo("No fountain file is currently targeted")

  pdfExport: (editor) ->
    activeEditor = @editorOrActiveEditor(editor)
    unless activeEditor.getGrammar().scopeName == 'source.fountain'
      atom.notifications.addInfo("No fountain file is currently targeted")
      return

    if (activeEditor)
      activeEditorPath = activeEditor.getPath()
      if !activeEditorPath
        return atom.notifications.addInfo("File must be saved to export PDF")
      text = activeEditor.getSelectedText() || activeEditor.getText()
      pdfConverter = new PdfConverter()
      pdfConverter.createPdf(activeEditorPath, text).then (uri) ->
        if uri then atom.workspace.open(uri, {"searchAllPanes":true})
    else
      atom.notifications.addInfo("No fountain file is currently targeted")

  uriForEditor: (editor) ->
    "fountain-preview://editor/#{editor.id}"

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()

    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(uri, options).then (fountainPreviewView) ->
      if isFountainPreviewView(fountainPreviewView)
        previousActivePane.activate()
