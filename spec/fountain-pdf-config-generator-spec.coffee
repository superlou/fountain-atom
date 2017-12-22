PdfConfigGenerator = require '../lib/fountain-pdf-config-generator'
fs = require 'fs'
path = require 'path'

describe 'Fountain PDF Config Generator', ->

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage 'fountain'

  # sanity checks
  it 'should have loaded fountain package', ->
    expect(atom.packages.isPackageActive('fountain')).toBeTruthy()


  describe 'setting/writing package settings configs', ->

    flag = false
    config = null

    beforeEach ->
      flag = false
      @configGenerator = new PdfConfigGenerator()
      config = {
       "print_title_page": false,
       "print_profile": "a4",
       "print_watermark": "BOOP"
      }

    it 'should be able to set string', ->
      section = 'settings5'
      property = 'print_watermark'

      atom.config.set('fountain.'+section+'.'+property, config[property])
      retVal = null

      runs () ->
        @configGenerator.createConfig().then (data) =>
          retVal = data
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 3000

      runs () ->
        expect(retVal[property]).toEqual(config[property])

    it 'should be able to set enum', ->
      section = 'settings1'
      property = 'print_profile'

      atom.config.set('fountain.'+section+'.'+property, config[property])
      retVal = null

      runs () ->
        @configGenerator.createConfig().then (data) =>
          retVal = data
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 3000

      runs () ->
        expect(retVal[property]).toEqual(config[property])

    it 'should be able to set boolean', ->
      section = 'settings1'
      property = 'print_title_page'

      atom.config.set('fountain.'+section+'.'+property, config[property])
      retVal = null

      runs () ->
        @configGenerator.createConfig().then (data) =>
          retVal = data
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 3000

      runs () ->
        expect(retVal[property]).toEqual(config[property])