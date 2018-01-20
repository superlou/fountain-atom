PdfConverter = require '../lib/fountain-pdf-converter'
fs = require 'fs'
path = require 'path'

describe 'Fountain PDF Converter', ->

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage 'fountain'

  # sanity checks
  it 'should have loaded fountain package', ->
    expect(atom.packages.isPackageActive('fountain')).toBeTruthy()


  describe 'conversion paths', ->

    asyncMaxWaitTime = 5000
    flag = false

    beforeEach ->
      @pdfConverter = new PdfConverter()
      flag = false

    it 'should be able to save new pdf', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addSuccess')
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileName = path.join(packagePath, 'spec/test_files/grammar-tests.fountain')
      pdfName = path.join(packagePath, 'spec/test_files/grammar-tests.pdf')
      fileContent = fs.readFileSync(fileName, "utf8")

      runs () ->
        @pdfConverter.toFile(path.parse(fileName), fileContent).then () ->
          flag = true
      , asyncMaxWaitTime

      waitsFor () ->
        return flag
      , "flag set", asyncMaxWaitTime

      runs () ->
        fileBuffer = fs.readFileSync(pdfName)
        expect(fileBuffer).toBeTruthy()
        expect(atom.notifications.addError).not.toHaveBeenCalled()
        expect(atom.notifications.addSuccess).toHaveBeenCalled()
        flag = false
        fs.unlink pdfName, () ->
          flag = true

      waitsFor () ->
        return flag
      , "flag set", asyncMaxWaitTime

      runs () ->
        expect(() -> fs.readFileSync(pdfName)).toThrow()

    it 'should not prompt for confirmation if no pdf exists', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addSuccess')
      spyOn(atom, "confirm")
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileName = path.join(packagePath, 'spec/test_files/grammar-tests.fountain')
      pdfName = path.join(packagePath, 'spec/test_files/grammar-tests.pdf')
      fileContent = fs.readFileSync(fileName, "utf8")

      runs () ->
        @pdfConverter.initiateConversion(fileName, fileContent).then () ->
          flag = true
      , asyncMaxWaitTime

      waitsFor () ->
        return flag
      , "flag set", asyncMaxWaitTime

      runs () ->
        fileBuffer = fs.readFileSync(pdfName)
        expect(fileBuffer).toBeTruthy()
        expect(atom.confirm).not.toHaveBeenCalled()
        expect(atom.notifications.addError).not.toHaveBeenCalled()
        expect(atom.notifications.addSuccess).toHaveBeenCalled()

    it 'should be able to cancel overwrite of existing pdf', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addSuccess')
      spyOn(atom, "confirm").andReturn(1)
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileName = path.join(packagePath, 'spec/test_files/grammar-tests.fountain')
      pdfName = path.join(packagePath, 'spec/test_files/grammar-tests.pdf')
      fileContent = fs.readFileSync(fileName, "utf8")

      runs () ->
        @pdfConverter.initiateConversion(fileName, fileContent).then () ->
          flag = true
      , asyncMaxWaitTime

      waitsFor () ->
        return flag
      , "flag set", asyncMaxWaitTime

      runs () ->
        fileBuffer = fs.readFileSync(pdfName)
        expect(fileBuffer).toBeTruthy()
        expect(atom.confirm).toHaveBeenCalled()
        expect(atom.notifications.addError).not.toHaveBeenCalled()
        expect(atom.notifications.addSuccess).not.toHaveBeenCalled()

    it 'should be able to overwrite existing pdf', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addSuccess')
      spyOn(atom, "confirm").andReturn(0)
      packagePath = atom.packages.resolvePackagePath('fountain')
      fileName = path.join(packagePath, 'spec/test_files/grammar-tests.fountain')
      pdfName = path.join(packagePath, 'spec/test_files/grammar-tests.pdf')
      fileContent = fs.readFileSync(fileName, "utf8")
      runs () ->
        @pdfConverter.initiateConversion(fileName, fileContent).then () ->
          flag = true
      , asyncMaxWaitTime

      waitsFor () ->
        return flag
      , "flag set", asyncMaxWaitTime

      runs () ->
        fileBuffer = fs.readFileSync(pdfName)
        expect(fileBuffer).toBeTruthy()
        expect(atom.confirm).toHaveBeenCalled()
        expect(atom.notifications.addError).not.toHaveBeenCalled()
        expect(atom.notifications.addSuccess).toHaveBeenCalled()
        fs.unlink pdfName, () ->
          flag = true

      waitsFor () ->
        return flag
      , "flag set", asyncMaxWaitTime

      runs () ->
        expect(() -> fs.readFileSync(pdfName)).toThrow()
