#afterwriting = require '../node_modules/afterwriting/bundle/js/afterwriting.js'
child_process = require 'child_process'
fs = require 'fs'

class PdfConverter

  toFile: (fileName, fileText) =>
    [fileCommonName, fileExtension] = fileName.split('.')
    timeStamp = new Date().getTime()
    tempFileName = "tmp#{timeStamp}.fountain"
    console.log(fileCommonName)
    console.log(fileExtension)
    fs.writeFile(tempFileName, fileText, (err) =>
      if (err)
        throw err
      console.log("The temp file #{tempFileName} has been saved!")

      child_process.exec "node ../.atom/dev/packages/fountain/node_modules/afterwriting/awc.js --source #{tempFileName} --pdf #{fileCommonName+timeStamp}.pdf", (err, stdout, stderr) =>
        if (err)
          console.error(err)
          return
        console.log(stdout)
    )

module.exports = PdfConverter