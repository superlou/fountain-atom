child_process = require 'child_process'
fs = require 'fs'

class PdfConverter

  createPreview: (projectPath, fileName, fileText) ->
    initiateConversion(projectPath, fileName, fileText, true)

  createPdf: (projectPath, fileName, fileText) ->
    initiateConversion(projectPath, fileName, fileText)

  initiateConversion = (projectPath, fileName, fileText, isPreview=false) ->

    [fileCommonName, fileExtension] = fileName.split('.')

    #only prompt for save if not temp && overwriting
    if isPreview
      toFile(projectPath, fileName, fileText, isPreview)
    else
      try
        # make cross-platform for the overwrite check
        fs.readFileSync("#{projectPath + '/' + fileCommonName}.pdf")
        choice = atom.confirm
          message: "File exists..."
          detailedMessage: "File #{fileCommonName}.pdf already exists.  Would you like to overwrite?"
          buttons: ["Yes", "No"]
        if choice == 0
          toFile(projectPath, fileName, fileText, isPreview)
      catch err
        toFile(projectPath, fileName, fileText, isPreview)

  toFile = (projectPath, fileName, fileText, isPreview=false) ->

    [fileCommonName, fileExtension] = fileName.split('.')
    timeStamp = new Date().getTime()
    tempFileName = "tmp#{timeStamp}.fountain"

    # write a temp file to pass to command line tool
    fs.writeFileSync(tempFileName, fileText)

    # construct relevant paths
    packagePath = atom.packages.resolvePackagePath('fountain')
    afterwritingPath = "#{packagePath}/node_modules/afterwriting/awc.js"
    packageTempPath = packagePath + "/temp"
    outputFullPath = "#{if isPreview then packageTempPath else projectPath}/#{if isPreview then '(preview) ' else ''}#{fileCommonName}.pdf"
    configPath = "#{packagePath}/configs/afterwritingConfig.json"

    # hopefully account for OS differences
    # TODO: FIX THIS UP... and maybe use node path module above
    linuxCommand = "node #{afterwritingPath} --source #{tempFileName} --pdf \"#{outputFullPath}\" --config #{configPath} --overwrite"
    windowsCommand = "node #{packagePath}\\node_modules\\afterwriting\\awc.js --source #{tempFileName} --pdf #{fileCommonName}.pdf --config #{packagePath}\\configs\\afterwritingConfig.json --overwrite"
    systemSpecificCommand
    if (process.platform == 'win32')
      systemSpecificCommand = windowsCommand
    else
      systemSpecificCommand = linuxCommand

    # execute command to generate pdf
    child_process.execSync systemSpecificCommand
    if !isPreview
      atom.notifications.addSuccess("New file #{fileCommonName}.pdf has been saved")

    # delete temp file
    fs.unlink(tempFileName, (status) =>
      if (status == -1)
        atom.notifications.addError("Failed Deleting Temp File", {'detail': "Status: #{status}"})
    )

    outputFullPath


module.exports = PdfConverter