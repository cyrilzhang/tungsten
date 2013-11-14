// Generated by CoffeeScript 1.6.3
var Compiler, Parser, trimSpaces;

trimSpaces = function(str) {
  return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
};

Parser = {
  findProneIndices: function(str, open_brackets, close_brackets, literal_markers) {
    var bracket_level, c, close, i, lit, literal_level, open, prone, _i, _j, _k, _ref, _ref1, _ref2;
    bracket_level = [];
    literal_level = [];
    for (i = _i = 1, _ref = open_brackets.length; 1 <= _ref ? _i <= _ref : _i >= _ref; i = 1 <= _ref ? ++_i : --_i) {
      bracket_level.push(0);
    }
    for (i = _j = 1, _ref1 = literal_markers.length; 1 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 1 <= _ref1 ? ++_j : --_j) {
      literal_level.push(0);
    }
    prone = [];
    for (i = _k = 0, _ref2 = str.length - 1; 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; i = 0 <= _ref2 ? ++_k : --_k) {
      c = str.charAt(i);
      lit = literal_markers.indexOf(c);
      open = open_brackets.indexOf(c);
      close = close_brackets.indexOf(c);
      if (lit !== -1) {
        literal_level[lit] = 1 - literal_level[lit];
      } else if (_.without(literal_level, 0).length === 0) {
        if (open !== -1) {
          bracket_level[open] += 1;
        } else if (close !== -1) {
          bracket_level[close] -= 1;
        } else if (_.without(literal_level, 0).length === 0 && _.without(bracket_level, 0).length === 0) {
          prone.push(i);
        }
      }
    }
    return prone;
  },
  parseAt: function(str) {
    var commas, equals, expr, i, pos, prone, raw_subs, sub, subs, this_sub, this_var, x, _i, _j, _k, _len, _ref, _ref1;
    pos = str.search(" at ");
    if (pos === -1) {
      return null;
    }
    expr = trimSpaces(str.substr(0, pos));
    if (expr === "") {
      return {
        error: "substitution with empty expression"
      };
    }
    raw_subs = str.substr(pos + 4);
    prone = Parser.findProneIndices(raw_subs, "([{", ")]}", "'\"`");
    commas = [-1];
    for (i = _i = 0, _len = prone.length; _i < _len; i = ++_i) {
      x = prone[i];
      if (raw_subs.charAt(x) === ',') {
        commas.push(i);
      }
    }
    commas.push(str.length);
    subs = [];
    for (i = _j = 0, _ref = commas.length - 2; 0 <= _ref ? _j <= _ref : _j >= _ref; i = 0 <= _ref ? ++_j : --_j) {
      sub = trimSpaces(raw_subs.substr(commas[i] + 1, commas[i + 1] - commas[i] - 1));
      equals = [];
      for (i = _k = 0, _ref1 = sub.length - 1; 0 <= _ref1 ? _k <= _ref1 : _k >= _ref1; i = 0 <= _ref1 ? ++_k : --_k) {
        if (raw_subs.charAt(i) === '=' && raw_subs.charAt(i + 1) !== '=' && raw_subs.charAt(i - 1) !== '=') {
          equals.push(i);
        }
      }
      if (equals.length === 0) {
        return {
          error: "substitution with no '=' tokens"
        };
      } else if (equals.length >= 2) {
        return {
          error: "substitution with too many '=' tokens"
        };
      } else {
        this_var = trimSpaces(sub.substr(0, equals[0]));
        this_sub = trimSpaces(sub.substr(equals[0] + 1));
        if (this_var === "") {
          return {
            error: "substitution with no variable"
          };
        }
        if (this_sub === "") {
          return {
            error: "substitution with no expression"
          };
        }
        subs.push({
          "var": this_var,
          sub: Parser.parseExpr(this_sub)
        });
      }
    }
    if (subs.length === 0) {
      return {
        error: "no substitutions"
      };
    }
    return {
      type: "at",
      body: Parser.parseExpr(expr),
      subs: subs
    };
  },
  parseLet: function(str) {
    return null;
  },
  resolveNaturalLiterals: function(str) {
    var chunk, i, in_nat, pos, prone, ret, x, _i, _len;
    prone = Parser.findProneIndices(str, "", "", "'\"");
    prone.push(str.length);
    pos = -1;
    in_nat = 0;
    ret = [];
    for (i = _i = 0, _len = prone.length; _i < _len; i = ++_i) {
      x = prone[i];
      if (x === str.length || str.charAt(x, prone) === '`') {
        chunk = str.substr(pos + 1, x - pos - 1);
        if (in_nat) {
          ret.push(' WolframAlpha[ "', chunk, '", "MathematicaResult" ] ');
        } else {
          ret.push(' ', chunk, ' ');
        }
        pos = x;
        in_nat = 1 - in_nat;
      }
    }
    return ret.join('');
  },
  resolveLineVariables: function(str) {
    var hits, m, match_pos, prone, raw_hits, re, result;
    prone = Parser.findProneIndices(str, "", "", "'\"`");
    prone.push(str.length);
    re = /<([1-9][0-9]*)>/g;
    raw_hits = _.uniq(str.match(re));
    hits = raw_hits.map(function(x) {
      return parseInt(x.substr(1, x.length - 2) - 1);
    });
    match_pos = -1;
    result = [];
    hits = [];
    while (m = re.exec(str)) {
      if (_.contains(prone, m.index)) {
        result.push(str.substr(match_pos + 1, m.index - match_pos - 1), " InternalVar", m[1], " ");
        match_pos = m.index + m[0].length - 1;
        hits.push(parseInt(m[1]) - 1);
      }
    }
    result.push(str.substr(match_pos + 1));
    hits = _.uniq(hits);
    return {
      type: "expr",
      expr: result.join(''),
      hits: hits
    };
  },
  parseExpr: function(str) {
    var ret;
    ret = Parser.resolveLineVariables(str);
    ret.expr = Parser.resolveNaturalLiterals(ret.expr);
    return ret;
  },
  parse: function(str) {
    var p_at, p_let;
    p_let = Parser.parseLet(str);
    p_at = Parser.parseAt(str);
    if (p_let !== null) {
      return null;
    }
    if (p_at !== null) {
      return p_at;
    }
    return Parser.parseExpr(str);
  }
};

Compiler = {
  compileExpr: function(tree) {
    return tree.expr;
  },
  compile: function(tree) {
    var context, i, query, ret, sub, _i, _len, _ref;
    context = [];
    if (tree.type === "at") {
      ret = [" ( ", Compiler.compileExpr(tree.body), " /. ", " { "];
      _ref = tree.subs;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        sub = _ref[i];
        if (i !== 0) {
          ret.push(" , ");
        }
        ret.push(sub["var"], " -> ", Compiler.compileExpr(sub.sub));
      }
      ret.push(" } ) ");
      query = ret.join('');
    } else if (tree.type === "expr") {
      query = Compiler.compileExpr(tree);
    }
    return {
      query: query
    };
  }
};
