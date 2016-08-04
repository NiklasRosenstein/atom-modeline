# -*- mode: coffee; encoding: utf8; tab-width: foo; tab: soft -*-
#Copyright (c) 2016  Niklas Rosenstein
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module.exports = modeline =

  activate: (state) =>
    atom.workspace.observeTextEditors (ed) =>
      lines = ed.getText().split "\n"
      for line in lines
        modes = modeline.match line
        if modes == null
          break
        is_valid_modeline = false
        for mode in modes
          if modeline.handle(ed, mode)
            is_valid_modeline = true

  match: (line) =>
    if line and line[0] == '#'
      result = line.match /[\w\d\-\._]+:\s*[\w\d\-\._]+;?/g
      if result == null
        result = []
    else
      result = null
    return result

  handle: (ed, mode) =>
    match = mode.split ":"
    if match.length != 2
      return false
    key = match[0].toLowerCase()
    value = match[1].replace /^\s+|\s*;?$/g, ""
    switch key
      when "encoding"
        ed.setEncoding(value)
      when "tab-width"
        value = parseInt(value, 10)
        if value
          ed.setTabLength(value)
        else
          console.log "invalid tab-width:", value
      when "tab"
        if value.toLowerCase() == "soft"
          ed.setSoftTabs(true)
        else if value.toLowerCase() == "hard"
          ed.setSoftTabs(false)
        else
          console.log "invalid value for tab:", value
      when "mode"
        atom.packages.onDidActivateInitialPackages () =>
          grammar = null
          for prefix in ['source.', 'text.']
            grammar = atom.grammars.grammarForScopeName(prefix + value)
            if grammar
               break
          if not grammar
            console.log "Could not find grammar for mode:", value
          else
            console.log "Setting grammar", grammar
            ed.setGrammar grammar
    return true
