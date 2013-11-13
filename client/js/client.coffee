trimSpaces = (str) ->
    return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '')

Parser = {
    # if structure not recognized, return null
    # if syntax error, return {error: "msg"}
    # otherwise, return an Object

    findProneIndices: (str, open_brackets, close_brackets, literal_markers) ->
        # array of indices at lowest bracket level
        # this is shitty
        bracket_level = []
        literal_level = []
        for i in [1..open_brackets.length]
            bracket_level.push(0)
        for i in [1..literal_markers.length]
            literal_level.push(0)

        prone = []
        for i in [0..str.length-1]
            c = str.charAt(i)
            lit = literal_markers.indexOf(c)
            open = open_brackets.indexOf(c)
            close = close_brackets.indexOf(c)
            if lit != -1
                literal_level[lit] = 1 - literal_level[lit]
            else if _.without(literal_level,0).length == 0
                if open != -1
                    bracket_level[open] += 1
                else if close != -1
                    bracket_level[close] -= 1
                else if _.without(literal_level,0).length == 0 and _.without(bracket_level,0).length == 0
                    prone.push(i)
        return prone
    parseAt: (str) ->
        pos = str.search(" at ")
        if pos == -1
            return null
        expr = trimSpaces(str.substr(0, pos))
        if expr == ""
            return {error: "substitution with empty expression"}
        raw_subs = str.substr(pos+4)
        prone = Parser.findProneIndices(raw_subs, "([{", ")]}", "'\"`")
        commas = [-1]
        for x, i in prone
            commas.push(i) if raw_subs.charAt(x) == ','
        commas.push(str.length)

        subs = []
        for i in [0..commas.length-2]
            sub = trimSpaces(raw_subs.substr(commas[i]+1, commas[i+1] - commas[i] - 1))
            equals = []
            for i in [0..sub.length-1]
                equals.push(i) if raw_subs.charAt(i) == '=' and raw_subs.charAt(i+1) != '=' and raw_subs.charAt(i-1) != '='
            if equals.length == 0
                return {error: "substitution with no '=' tokens"}
            else if equals.length >= 2
                return {error: "substitution with too many '=' tokens"}
            else
                this_var = trimSpaces(sub.substr(0, equals[0]))
                this_sub = trimSpaces(sub.substr(equals[0]+1))
                if this_var == ""
                    return {error: "substitution with no variable"}
                if this_sub == ""
                    return {error: "substitution with no expression"}
                subs.push({ var:this_var, sub: Parser.parseExpr(this_sub) })
        if subs.length == 0
            return {error: "no substitutions"}

        return {type: "at", body: Parser.parseExpr(expr), subs: subs}
    parseLet: (str) ->
        return null
    resolveNaturalLiterals: (str) ->
        prone = Parser.findProneIndices(str, "", "", "'\"")
        prone.push(str.length)
        pos = -1
        in_nat = 0
        ret = []
        for x, i in prone
            if x == str.length or str.charAt(x, prone) == '`'
                chunk = str.substr(pos+1, x-pos-1)
                if in_nat
                    ret.push( ' WolframAlpha[ "', chunk, '", "MathematicaResult" ] ' )
                else
                    ret.push( ' ', chunk, ' ' )
                pos = x
                in_nat = 1 - in_nat
        return ret.join('')
    resolveLineVariables: (str) ->
        prone = Parser.findProneIndices(str, "", "", "'\"`")
        prone.push(str.length)
        aux = []
        prev = 0
        for x in prone
            ++prev
            while prev < x
                aux.push(' ')
                ++prev
            aux.push(str.charAt(x))
        pronestr = aux.join('')

        raw_hits = _.uniq( pronestr.match(/<([1-9][0-9]*)>/g) )

        hits = raw_hits.map( (x) -> parseInt( x.substr(1,x.length-2) - 1 ) )
        
        return hits

    parseExpr: (str) ->
        str = Parser.resolveNaturalLiterals(str)
        return {type: "expr", expr: str}
    parse: (str) ->
        p_let = Parser.parseLet(str)
        p_at = Parser.parseAt(str)
        
        if p_let != null
            return null
        if p_at != null
            return p_at
        
        return Parser.parseExpr(str)
}

Compiler = {
    compileExpr: (tree) ->
        return tree.expr
    compile: (tree) ->
        context = []

        if tree.type == "at"
            ret = [" ( ", Compiler.compileExpr(tree.body), " /. " , " { "]
            for sub, i in tree.subs
                ret.push(" , ") unless i == 0
                ret.push(sub.var, " -> ", Compiler.compileExpr(sub.sub))
            ret.push(" } ) ")
            query = ret.join('')
        else if tree.type == "expr"
            query = Compiler.compileExpr(tree)

        return {query: query}
}

Controller = {
    url: 'http://127.0.0.1:8000/'
    get: (msg, callback, ajaxerr_callback, syntaxerr_callback) ->
        tree = Parser.parse(" " + msg + " ")
        if tree.error?
            syntaxerr_callback(tree.error)
        else
            compiled = Compiler.compile(tree)
            data = []
            data.push("OutputData = " + compiled.query)
            $.post( Controller.url, {data: data.join('')}, callback )
                .error(ajaxerr_callback)
}

Prompt = {
    count: 1
    active: null
    history: []
    results: []
    history_pos: 0
    toggles: [true, false, false]
    dots: null
    make: (prefix, content) ->
        p = $('<div class="prompt-p"/>').text(prefix)
        c = $('<input type="text" class="prompt-c"/>').val(content)
        # c = $('<div contenteditable="true" class="prompt-c"/>').val(content)
        return block = $('<div class="prompt-b"/>').append(p, c)
    hist: (prefix, content) ->
        block = Prompt.make(prefix, content)
        block.find('input').attr('readonly', 'readonly')
        $('#container').append(block)
    submit: ->
        unless Prompt.active.find(".prompt-c").is(":focus")
            Prompt.active.find(".prompt-c").focus()
            return
        cmd = Prompt.active.find(".prompt-c").val()
        if cmd == "" then return
        Prompt.active.hide()
        Prompt.ndots = 0
        Prompt.dots.show()
        Prompt.history.push(cmd)
        Prompt.history_pos = Prompt.history.length
        Prompt.hist(Prompt.count + ">", cmd)
        out = Controller.get(cmd, Prompt.success, Prompt.ajaxError, Prompt.syntaxError)
    success: (out) ->
        segments = out.split('%%%')
        segments[0] = trimSpaces(segments[0])
        segments[1] = trimSpaces(segments[1])

        block = $('<div class="output texrender"/>').text("$" + segments[0] + "$")
        line1 = $('<div class="output texcode"/>').text(segments[0])
        line2 = $('<div class="output mathcode"/>').text(segments[1])

        block.hide() unless Prompt.toggles[0]
        line1.hide() unless Prompt.toggles[1]
        line2.hide() unless Prompt.toggles[2]

        Prompt.results.push(segments[1])

        $('#container').append(block, line1, line2)
        MathJax.Hub.Queue(["Typeset", MathJax.Hub, block[0]]);

        Prompt.next(true)
    next: (success) ->
        if success
            Prompt.count += 1
        Prompt.active.show()
        Prompt.dots.hide()
        Prompt.active.find(".prompt-p").text(Prompt.count + ">")
        Prompt.active.find(".prompt-c").val("").focus()
        $('html, body').scrollTop($(document).height())
    ajaxError: (out) ->
        errline = $('<div class="output error"/>').text("Connection error")
        $('#container').append(errline)
        Prompt.next(false)
    syntaxError: (out) ->
        errline = $('<div class="output error"/>').text("Syntax error: " + out)
        $('#container').append(errline)
        Prompt.next(false)
    up: ->
        if Prompt.history_pos > 0
            --Prompt.history_pos
            Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos])
        false
    down: ->
        if Prompt.history_pos < Prompt.history.length
            ++Prompt.history_pos
            if Prompt.history_pos == Prompt.history.length
                Prompt.active.find(".prompt-c").val("")
            else
                Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos])
        false

    ndots: 0
    tick: ->
        Prompt.ndots = (Prompt.ndots+1) % 5
        Prompt.dots.text(Array(Prompt.ndots+2).join("."))
}

$ ->
    Prompt.active = $("#prompt").append( Prompt.make("", "") )
    Prompt.active.find(".prompt-p").text(Prompt.count + ">")
    Prompt.dots = $("#dots")
    setInterval(Prompt.tick, 100)

    $("#wa").click( -> location.reload() )

    $("#toggl1").click( (e) ->
        $("#toggl1").toggleClass("down")
        Prompt.toggles[0] = not Prompt.toggles[0]
        if Prompt.toggles[0] then $(".texrender").show() else $(".texrender").hide()
        window.scrollTo(0, document.body.scrollHeight)
    )

    $("#toggl2").click( (e) ->
        $("#toggl2").toggleClass("down")
        Prompt.toggles[1] = not Prompt.toggles[1]
        if Prompt.toggles[1] then $(".texcode").show() else $(".texcode").hide()
        window.scrollTo(0, document.body.scrollHeight)
    )
    $("#toggl3").click( (e) ->
        $("#toggl3").toggleClass("down")
        Prompt.toggles[2] = not Prompt.toggles[2]
        if Prompt.toggles[2] then $(".mathcode").show() else $(".mathcode").hide()
        window.scrollTo(0, document.body.scrollHeight)
    )
    $(window).keydown((e) ->
        switch e.which
            when 13 then Prompt.submit()
            when 38 then Prompt.up()
            when 40 then Prompt.down()
            when 17, 91 then false
    ).click( (e) ->
        Prompt.active.find(".prompt-c").focus() if e.target.id == "parent-target" )
    Prompt.active.find(".prompt-c").focus()