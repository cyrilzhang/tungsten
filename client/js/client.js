// Generated by CoffeeScript 1.6.3
var Controller, Prompt;

Controller = {
  get: function(msg, callback) {
    var out,
      _this = this;
    out = $('<div class="output"/>').text(msg.toUpperCase());
    return setTimeout((function() {
      return callback(out);
    }), 100);
  }
};

Prompt = {
  count: 1,
  active: null,
  history: [],
  history_pos: 0,
  make: function(prefix, content) {
    var block, c, p;
    p = $('<div class="prompt-p"/>').text(prefix);
    c = $('<input type="text" class="prompt-c"/>').val(content);
    return block = $('<div class="prompt-b"/>').append(p, c);
  },
  hist: function(prefix, content) {
    var block;
    block = Prompt.make(prefix, content);
    block.find('input').attr('readonly', 'readonly');
    return $('#container').append(block);
  },
  submit: function() {
    var cmd, out;
    if (!Prompt.active.find(".prompt-c").is(":focus")) {
      Prompt.active.find(".prompt-c").focus();
      return;
    }
    cmd = Prompt.active.find(".prompt-c").val();
    if (cmd === "") {
      return;
    }
    Prompt.active.hide();
    Prompt.history.push(cmd);
    Prompt.history_pos = Prompt.history.length;
    Prompt.hist(Prompt.count + ">", cmd);
    return out = Controller.get(cmd, Prompt.next);
  },
  next: function(out) {
    $('#container').append(out);
    Prompt.count += 1;
    Prompt.active.show();
    Prompt.active.find(".prompt-p").text(Prompt.count + ">");
    Prompt.active.find(".prompt-c").val("").focus();
    return $('html, body').scrollTop($(document).height());
  },
  up: function() {
    if (Prompt.history_pos > 0) {
      --Prompt.history_pos;
      Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos]);
    }
    return false;
  },
  down: function() {
    if (Prompt.history_pos < Prompt.history.length) {
      ++Prompt.history_pos;
      if (Prompt.history_pos === Prompt.history.length) {
        Prompt.active.find(".prompt-c").val("");
      } else {
        Prompt.active.find(".prompt-c").val(Prompt.history[Prompt.history_pos]);
      }
    }
    return false;
  }
};

$(function() {
  Prompt.active = $("#prompt").append(Prompt.make("", ""));
  Prompt.active.find(".prompt-p").text(Prompt.count + ">");
  $(window).keydown(function(e) {
    switch (e.which) {
      case 13:
        return Prompt.submit();
      case 38:
        return Prompt.up();
      case 40:
        return Prompt.down();
      default:
        return Prompt.active.find(".prompt-c").focus();
    }
  }).click(function(e) {
    if (e.target === this) {
      return Prompt.active.find(".prompt-c").focus();
    }
  });
  return Prompt.active.find(".prompt-c").focus();
});
