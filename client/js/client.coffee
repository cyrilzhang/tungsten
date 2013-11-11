Controller = {
    url: 'http://127.0.0.1:8000/'
    get: (msg, callback, err_callback) ->
        $.post( Controller.url, {data: translate(msg)}, callback )
            .error(err_callback)
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
        out = Controller.get(cmd, Prompt.success, Prompt.error)
    success: (out) ->
        segments = out.split('%%%')
        segments[0].replace(/^\s\s*/, '').replace(/\s\s*$/, '');
        segments[1].replace(/^\s\s*/, '').replace(/\s\s*$/, '');

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
    error: (out) ->
        errline = $('<div class="output error"/>').text("Connection error")
        $('#container').append(errline)
        Prompt.next()
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
        if Prompt.toggles[0] then $(".texrender").show() else $(".texrender").hide() )
    $("#toggl2").click( (e) ->
        $("#toggl2").toggleClass("down")
        Prompt.toggles[1] = not Prompt.toggles[1]
        if Prompt.toggles[1] then $(".texcode").show() else $(".texcode").hide() )
    $("#toggl3").click( (e) ->
        $("#toggl3").toggleClass("down")
        Prompt.toggles[2] = not Prompt.toggles[2]
        if Prompt.toggles[2] then $(".mathcode").show() else $(".mathcode").hide() )
    $(window).keydown((e) ->
        switch e.which
            when 13 then Prompt.submit()
            when 38 then Prompt.up()
            when 40 then Prompt.down()
            when 17, 91 then false
    ).click( (e) ->
        Prompt.active.find(".prompt-c").focus() if e.target.id == "parent-target" )
    Prompt.active.find(".prompt-c").focus()