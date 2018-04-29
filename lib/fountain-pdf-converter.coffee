{BufferedNodeProcess} = require 'atom'
fs = require 'fs'
path = require 'path'
PdfConfigGenerator = require './fountain-pdf-config-generator.coffee'

class PdfConverter

  configGenerator = new PdfConfigGenerator()

  createPreview: (projectPath, fileText) ->
    @initiateConversion(projectPath, fileText, true)

  createPdf: (projectPath, fileText) ->
    @initiateConversion(projectPath, fileText)

  initiateConversion: (projectPath, fileText, isPreview=false) ->

    parsedPath = path.parse(projectPath)

    #only prompt for save if not temp && overwriting
    if isPreview
      @toFile(parsedPath, fileText, isPreview)
    else
      try
        # make cross-platform for the overwrite check
        fs.readFileSync(path.join(parsedPath.dir, "#{parsedPath.name}.pdf"))
        choice = atom.confirm
          message: "File exists..."
          detailedMessage: "File #{parsedPath.name}.pdf already exists.  Would you like to overwrite?"
          buttons: ["Yes", "No"]
        if choice == 0
          @toFile(parsedPath, fileText, isPreview)
        else
          Promise.resolve()
      catch err
        @toFile(parsedPath, fileText, isPreview)

  toFile: (parsedPath, fileText, isPreview=false) ->

    timeStamp = new Date().getTime()

    # construct paths
    packagePath = atom.packages.resolvePackagePath('fountain')
    packageTempPath = path.join(packagePath, "temp")
    tempFilePath = path.join(packageTempPath, "tmp#{timeStamp}.fountain")
    afterwritingPath = path.join(packagePath, "node_modules", "afterwriting", "awc.js")
    outputFullPath = path.join("#{if isPreview then packageTempPath else parsedPath.dir}", "#{if isPreview then '(preview) ' else ''}#{parsedPath.name}.pdf")
    configPath = path.join(packagePath, "configs", "afterwritingConfig.json")
    fontsPath = path.join(packagePath, "configs", "afterwritingFonts.json")

    notifyBegin = () =>
      if isPreview
        atom.notifications.addSuccess("Generating preview for \"#{parsedPath.name}.fountain\"")
      else
        atom.notifications.addSuccess("Generating file \"#{parsedPath.name}.pdf\"")
      return Promise.resolve()

    writeTempFile = () =>
      return new Promise (resolve, reject) =>
        fs.writeFile(tempFilePath, fileText, resolve)

    generatePdf = () =>
      command = afterwritingPath
      args = ['--source', tempFilePath, '--pdf', outputFullPath, '--config', configPath, "--fonts", fontsPath, '--overwrite']
      stdout = (output) -> console.log(output)
      stderr = (output) -> console.error(output)
      return new Promise (resolve, reject) =>
         new BufferedNodeProcess({command: command, args: args, stdout: stdout, stderr: stderr, exit: resolve})

    notifySuccess = () =>
      if !isPreview
          atom.notifications.addSuccess("New file \"#{parsedPath.name}.pdf\" has been created")
      return Promise.resolve()

    deleteTempFile = () =>
      return new Promise (resolve, reject) =>
        fs.unlink(tempFilePath, resolve)

    getFullPath = () =>
      return Promise.resolve(outputFullPath)

    return notifyBegin()
      .then(configGenerator.createConfig)
      .then(writeTempFile)
      .then(generatePdf)
      .then(notifySuccess)
      .then(deleteTempFile)
      .then(getFullPath)


module.exports = PdfConverter
