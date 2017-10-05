PdfConverter = require '../lib/fountain-pdf-converter'
fs = require 'fs'

describe 'Fountain PDF Converter', ->

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage 'fountain'

  # sanity checks
  it 'should have loaded fountain package', ->
    expect(atom.packages.isPackageActive('fountain')).toBeTruthy()


  describe 'conversion paths', ->

    flag = false

    beforeEach ->
      @pdfConverter = new PdfConverter()
      flag = false

    it 'should be able to save new pdf', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addSuccess')
      fileName = 'grammar-tests.fountain'
      pdfName = 'grammar-tests.pdf'
      fileContent = fs.readFileSync('./spec/' + fileName, "utf8")

      runs () ->
        @pdfConverter.toFile("./", 'grammar-tests.fountain', fileContent).then () ->
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 750

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
      , "flag set", 750

      runs () ->
        expect(() -> fs.readFileSync(pdfName)).toThrow()

    it 'should not prompt for confirmation if no pdf exists', ->
      spyOn(atom.notifications, 'addError')
      spyOn(atom.notifications, 'addSuccess')
      spyOn(atom, "confirm")
      fileName = 'grammar-tests.fountain'
      pdfName = 'grammar-tests.pdf'
      fileContent = fs.readFileSync('./spec/' + fileName, "utf8")

      runs () ->
        @pdfConverter.initiateConversion("./", 'grammar-tests.fountain', fileContent).then () ->
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 750

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
      fileName = 'grammar-tests.fountain'
      pdfName = 'grammar-tests.pdf'
      fileContent = fs.readFileSync('./spec/' + fileName, "utf8")

      runs () ->
        @pdfConverter.initiateConversion("./", 'grammar-tests.fountain', fileContent).then () ->
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 750

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
      fileName = 'grammar-tests.fountain'
      pdfName = 'grammar-tests.pdf'
      fileContent = fs.readFileSync('./spec/' + fileName, "utf8")
      runs () ->
        @pdfConverter.initiateConversion("./", 'grammar-tests.fountain', fileContent).then () ->
          flag = true
      , 5000

      waitsFor () ->
        return flag
      , "flag set", 750

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
      , "flag set", 750

      runs () ->
        expect(() -> fs.readFileSync(pdfName)).toThrow()