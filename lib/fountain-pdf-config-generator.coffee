fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'

class PdfConfigGenerator

  createConfig: () ->

    packagePath = atom.packages.resolvePackagePath('fountain')
    configPath = path.join(packagePath, "configs", "afterwritingConfig.json")

    configs = atom.config.get('fountain')
    completeConfig = {}
    for subconfig in _.values(configs)
      _.extend(completeConfig, subconfig)

    jsonConfig = JSON.stringify(completeConfig, null, 1)

    writeConfigFile = () =>
      return new Promise (resolve, reject) =>
        fs.writeFile(configPath, jsonConfig, resolve)

    return writeConfigFile().then () => Promise.resolve(completeConfig)

module.exports = PdfConfigGenerator
