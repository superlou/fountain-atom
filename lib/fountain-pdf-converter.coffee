{BufferedNodeProcess} = require 'atom'
fs = require 'fs'
path = require 'path'

class PdfConverter

  createPreview: (projectPath, fileName, fileText) ->
    @initiateConversion(projectPath, fileName, fileText, true)

  createPdf: (projectPath, fileName, fileText) ->
    @initiateConversion(projectPath, fileName, fileText)

  initiateConversion: (projectPath, fileName, fileText, isPreview=false) ->

    [fileCommonName, fileExtension] = fileName.split('.')

    #only prompt for save if not temp && overwriting
    if isPreview
      @toFile(projectPath, fileName, fileText, isPreview)
    else
      try
        # make cross-platform for the overwrite check
        fs.readFileSync("#{projectPath + '/' + fileCommonName}.pdf")
        choice = atom.confirm
          message: "File exists..."
          detailedMessage: "File #{fileCommonName}.pdf already exists.  Would you like to overwrite?"
          buttons: ["Yes", "No"]
        if choice == 0
          @toFile(projectPath, fileName, fileText, isPreview)
        else
          Promise.resolve()
      catch err
        @toFile(projectPath, fileName, fileText, isPreview)

  toFile: (projectPath, fileName, fileText, isPreview=false) ->

    [fileCommonName, fileExtension] = fileName.split('.')
    timeStamp = new Date().getTime()

    # construct paths
    packagePath = atom.packages.resolvePackagePath('fountain')
    packageTempPath = path.join(packagePath, "temp")
    tempFilePath = path.join(packageTempPath, "tmp#{timeStamp}.fountain")
    afterwritingPath = path.join(packagePath, "node_modules", "afterwriting", "awc.js")
    outputFullPath = path.join("#{if isPreview then packageTempPath else projectPath}", "#{if isPreview then '(preview) ' else ''}#{fileCommonName}.pdf")
    configPath = path.join(packagePath, "configs", "afterwritingConfig.json")

    notifyBegin = () =>
      if isPreview
        atom.notifications.addSuccess("Generating preview for \"#{fileCommonName}.fountain\"")
      else
        atom.notifications.addSuccess("Generating file \"#{fileCommonName}.pdf\"")
      return Promise.resolve()

    writeTempFile = () =>
      return new Promise (resolve, reject) =>
        fs.writeFile(tempFilePath, fileText, resolve)

    generatePdf = () =>
      command = afterwritingPath
      args = ['--source', tempFilePath, '--pdf', outputFullPath, '--config', configPath, '--overwrite']
      stdout = (output) -> console.log(output)
      stderr = (output) -> console.error(output)
      return new Promise (resolve, reject) =>
         new BufferedNodeProcess({command: command, args: args, stdout: stdout, stderr: stderr, exit: resolve})

    notifySuccess = () =>
      if !isPreview
          atom.notifications.addSuccess("New file \"#{fileCommonName}.pdf\" has been created")
      return Promise.resolve()

    deleteTempFile = () =>
      return new Promise (resolve, reject) =>
        fs.unlink(tempFilePath, resolve)

    getFullPath = () =>
      return Promise.resolve(outputFullPath)

    return notifyBegin()
      .then(writeTempFile)
      .then(generatePdf)
      .then(notifySuccess)
      .then(deleteTempFile)
      .then(getFullPath)


module.exports = PdfConverter