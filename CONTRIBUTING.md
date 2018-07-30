## General
For general contributing guidelines, see [atom guidelines](https://github.com/atom/atom/blob/master/CONTRIBUTING.md)

## Issues
Logging an [issue](https://github.com/superlou/fountain-atom/issues) is a welcome contribution if you discover a bug or would like to see a key feature added to support your workflow.

## Pull Requests
When submitting a pull request to address an existing issue, please be sure to run all of the spec tests from the project's root directory: `atom --test ./spec/*`

Fountain files to support testing can be found in the `spec/test_files` directory.  New fountain test files may be added to this directory as needed, provided they fall under appropriate licensing.

## Contribute to Fountain for Atom
First of all, you have to fork the repository.  

**Mac or Linux**  
`apm develop fountain` *Atom clones the fountain repository in `~/github/fountain` and links it for development mode*  
`cd ~/github/fountain` *Go to the cloned folder*  
`git remote rename origin upstream` *Rename the source repository as upstream*  
`git remote add origin https://github.com/YourPseudo/fountain-atom.git` *Set your forked repository as origin*     
`atom -d .` *Open the fountain package in atom's development mode*

After every change you make, you need to do `View->Developer->Reload Window` to see them applied.
