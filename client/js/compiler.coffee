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

        re = /<([1-9][0-9]*)>/g
        raw_hits = _.uniq( str.match(re) )
        hits = raw_hits.map( (x) -> parseInt( x.substr(1,x.length-2) - 1 ) )

        match_pos = -1
        result = []
        hits = []
        while m = re.exec(str)
            if _.contains(prone, m.index)
                result.push( str.substr(match_pos+1, m.index - match_pos - 1), " InternalVar", m[1], " " )
                match_pos = m.index + m[0].length - 1
                hits.push(parseInt(m[1]) - 1)
        result.push( str.substr(match_pos+1) )
        hits = _.uniq(hits)
        return {type: "expr", expr: result.join(''), hits: hits}

    parseExpr: (str) ->
        ret = Parser.resolveLineVariables(str)
        ret.expr = Parser.resolveNaturalLiterals(ret.expr)
        return ret
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
    getLineVars: (tree) ->
        ret = []
        if tree.type == "expr"
            ret = tree.hits
        else if tree.type == "at"
            ret.push.apply(ret, Compiler.getLineVars(tree.body))
            for sub in tree.subs
                ret.push.apply(ret, Compiler.getLineVars(sub.sub))
        return _.uniq(ret)
    compileExpr: (tree) ->
        return tree.expr
    compile: (tree) ->
        linevars = Compiler.getLineVars(tree)
        for lv in linevars
            if lv >= Prompt.count
                return {error: "invalid line variable"}
        context = _.map( linevars, (x) -> "InternalVar#{(x+1)} = #{Prompt.results[x]}" )

        if tree.type == "at"
            ret = [" ( ", Compiler.compileExpr(tree.body), " /. " , " { "]
            for sub, i in tree.subs
                ret.push(" , ") unless i == 0
                ret.push(sub.var, " -> ", Compiler.compileExpr(sub.sub))
            ret.push(" } ) ")
            query = ret.join('')
        else if tree.type == "expr"
            query = Compiler.compileExpr(tree)

        return {query: query, context: context}
}
