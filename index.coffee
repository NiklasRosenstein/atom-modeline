# -*- mode: coffee; encoding: utf8; tab-width: 2; tab: soft -*-
# Copyright (c) 2016  Niklas Rosenstein
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
  # Set when Atom packages have been initialized. We want to set the
  # grammar only when all packages have been loaded, because they could
  # add new grammars.
  packagesInitialised: false

  # Register the text editor observer that checks for the modeline.
  activate: (state) ->
    atom.workspace.observeTextEditors (ed) =>
      lines = ed.getText().split "\n"
      found_modeline = false
      for line in lines
        if found_modeline
          break
        # TODO: Support other comment styles
        if line and line[0] == '#'
          result = line.match /[\w\d\-\._]+:\s*[\w\d\-\._]+;?/g
          if result
            for mode in result
              if modeline.handle(ed, mode)
                found_modeline = true
        else if line
          # We processed the whole first comment block, don't search
          # for a modeline anywhere else.
          break

  # Handles a single modeline option and updates the editor.
  handle: (ed, mode) ->
    # Split key: value pair.
    match = mode.split ":"
    if match.length != 2
      return false

    key = match[0].toLowerCase()
    if key of @aliases
      key = @aliases[key]
    value = match[1].replace /^\s+|\s*;?$/g, ""
    handler = @handlers[key]
    if handler
      handler ed, value
      return true
    else
     console.log "modeline: unknown option", key
     return false

  aliases:
    "coding": "encoding"

  handlers:
    "encoding": (ed, value) =>
      ed.setEncoding(value)
      console.log "modeline: encoding set to", value
    "tab": (ed, value) =>
      value = value.toLowerCase()
      if value == "soft"
        ed.setSoftTabs(true)
        console.log "modeline: enabled soft tabs"
      else if value == "hard"
        ed.setSoftTabs(false)
        console.log "modeline: enabled hard tabs"
      else
        console.log "modeline: invalid value for tab:", value
    "tab-width": (ed, value) =>
      value = parseInt(value, 10)
      if value
        ed.setTabLength(value)
        console.log "modeline: tab-width set to", value
      else
        console.log "modeline: invalid tab-width", value
    "mode": (ed, value) =>
      # Callback that processes the language mode.
      callback = () =>
        grammar = null
        for prefix in ['source.', 'text.']
          grammar = atom.grammars.grammarForScopeName(prefix + value)
          if grammar
             break
        if not grammar
          console.log "modeline: could not find grammar for mode", value
        else
          ed.setGrammar grammar
          console.log "modeline: grammar set to", grammar.name

      # If packages have already been initialized, we can do the
      # action directly, otherwise we have to wait until all packages
      # have been initialized.
      if @packagesInitialized
        callback()
      else
        console.log "modeline: waiting for packages to be initialized..."
        atom.packages.onDidActivateInitialPackages callback

atom.packages.onDidActivateInitialPackages () =>
  modeline.packagesInitialized = true
