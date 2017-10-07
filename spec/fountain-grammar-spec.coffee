grammarTest = require 'atom-grammar-test'

describe 'Fountain Grammar', ->
  beforeEach ->
    # Ensure you're language package is loaded
    waitsForPromise ->
      atom.packages.activatePackage 'fountain',

  grammarTest('spec/test_files/grammar-tests.fountain')
