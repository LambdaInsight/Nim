#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Path handling utilities for Nim. Strictly typed code in order
## to avoid the never ending time sink in getting path handling right.

import os, strutils, pathnorm

type
  AbsoluteFile* = distinct string
  AbsoluteDir* = distinct string
  RelativeFile* = distinct string
  RelativeDir* = distinct string

proc isEmpty*(x: AbsoluteFile): bool {.inline.} = x.string.len == 0
proc isEmpty*(x: AbsoluteDir): bool {.inline.} = x.string.len == 0
proc isEmpty*(x: RelativeFile): bool {.inline.} = x.string.len == 0
proc isEmpty*(x: RelativeDir): bool {.inline.} = x.string.len == 0

proc copyFile*(source, dest: AbsoluteFile) =
  os.copyFile(source.string, dest.string)

proc removeFile*(x: AbsoluteFile) {.borrow.}

proc splitFile*(x: AbsoluteFile): tuple[dir: AbsoluteDir, name, ext: string] =
  let (a, b, c) = splitFile(x.string)
  result = (dir: AbsoluteDir(a), name: b, ext: c)

proc extractFilename*(x: AbsoluteFile): string {.borrow.}

proc fileExists*(x: AbsoluteFile): bool {.borrow.}
proc dirExists*(x: AbsoluteDir): bool {.borrow.}

proc quoteShell*(x: AbsoluteFile): string {.borrow.}
proc quoteShell*(x: AbsoluteDir): string {.borrow.}

proc cmpPaths*(x, y: AbsoluteDir): int {.borrow.}

proc createDir*(x: AbsoluteDir) {.borrow.}

when true:
  proc eqImpl(x, y: string): bool {.inline.} =
    result = cmpPaths(x, y) == 0

  proc `==`*(x, y: AbsoluteFile): bool = eqImpl(x.string, y.string)
  proc `==`*(x, y: AbsoluteDir): bool = eqImpl(x.string, y.string)
  proc `==`*(x, y: RelativeFile): bool = eqImpl(x.string, y.string)
  proc `==`*(x, y: RelativeDir): bool = eqImpl(x.string, y.string)

  proc `/`*(base: AbsoluteDir; f: RelativeFile): AbsoluteFile =
    #assert isAbsolute(base.string)
    assert(not isAbsolute(f.string))
    result = AbsoluteFile newStringOfCap(base.string.len + f.string.len)
    var state = 0
    addNormalizePath(base.string, result.string, state)
    addNormalizePath(f.string, result.string, state)

  proc `/`*(base: AbsoluteDir; f: RelativeDir): AbsoluteDir =
    #assert isAbsolute(base.string)
    assert(not isAbsolute(f.string))
    result = AbsoluteDir newStringOfCap(base.string.len + f.string.len)
    var state = 0
    addNormalizePath(base.string, result.string, state)
    addNormalizePath(f.string, result.string, state)

  proc relativeTo*(fullPath: AbsoluteFile, baseFilename: AbsoluteDir;
                   sep = DirSep): RelativeFile =
    RelativeFile(relativePath(fullPath.string, baseFilename.string, sep))

  proc toAbsolute*(file: string; base: AbsoluteDir): AbsoluteFile =
    if isAbsolute(file): result = AbsoluteFile(file)
    else: result = base / RelativeFile file

  proc changeFileExt*(x: AbsoluteFile; ext: string): AbsoluteFile {.borrow.}
  proc changeFileExt*(x: RelativeFile; ext: string): RelativeFile {.borrow.}

  proc addFileExt*(x: AbsoluteFile; ext: string): AbsoluteFile {.borrow.}
  proc addFileExt*(x: RelativeFile; ext: string): RelativeFile {.borrow.}

  proc writeFile*(x: AbsoluteFile; content: string) {.borrow.}

when isMainModule:
  doAssert AbsoluteDir"/Users/me///" / RelativeFile"z.nim" == AbsoluteFile"/Users/me/z.nim"
  doAssert relativePath("/foo/bar.nim", "/foo/", '/') == "bar.nim"

when isMainModule and defined(windows):
  let nasty = string(AbsoluteDir(r"C:\Users\rumpf\projects\nim\tests\nimble\nimbleDir\linkedPkgs\pkgB-#head\../../simplePkgs/pkgB-#head/") / RelativeFile"pkgA/module.nim")
  doAssert nasty.replace('/', '\\') == r"C:\Users\rumpf\projects\nim\tests\nimble\nimbleDir\simplePkgs\pkgB-#head\pkgA\module.nim"
