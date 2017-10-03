child_process = require 'child_process'
fs = require 'fs'
path = require 'path'

class PdfConverter

  createPreview: (projectPath, fileName, fileText) ->
    initiateConversion(projectPath, fileName, fileText, true)

  createPdf: (projectPath, fileName, fileText) ->
    initiateConversion(projectPath, fileName, fileText)

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
      catch err
        @toFile(projectPath, fileName, fileText, isPreview)

  toFile: (projectPath, fileName, fileText, isPreview=false) ->

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

    packagePath = path.normalize(packagePath)
    afterwritingPath = path.normalize(afterwritingPath)
    packageTempPath = path.normalize(packageTempPath)
    outputFullPath = path.normalize(outputFullPath)
    configPath = path.normalize(configPath)

    conversionCommand = "node #{afterwritingPath} --source #{tempFileName} --pdf \"#{outputFullPath}\" --config #{configPath} --overwrite"

    # execute command to generate pdf
    child_process.execSync conversionCommand

    if !isPreview
      atom.notifications.addSuccess("New file #{fileCommonName}.pdf has been saved")

    # delete temp file
    fs.unlink(tempFileName, (status) =>
      if (status == -1)
        atom.notifications.addError("Failed Deleting Temp File", {'detail': "Status: #{status}"})
    )

    outputFullPath


module.exports = PdfConverter