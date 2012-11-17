currentFrame = null

$(document).ready ->
    $('.button').button()
    $('#set-layout1').click(-> setLayout(1))
    $('#set-layout2').click(-> setLayout(2))
    $('#set-layout3').click(-> setLayout(3))
    $('#save-question').click saveQuestion

    $('#preview-question').click previewQuestion
    createOptionEntries($('#question-container'), ['watched-input'])

    # update the preview every time text changes
    $('.watched-input').change previewQuestion

    previewQuestion()

    window.codePreview = CodeMirror.fromTextArea $('#latex-preview')[0], {'indentWithTabs': true, 'mode': 'text/x-stex'}

layout = 'layout2'
setLayout = (layout) ->
    layoutStr = if typeof layout is 'string' then layout else "layout#{layout}"
    $('#math-preview').removeClass('layout1 layout2 layout3')
    $('#math-preview').addClass(layoutStr)
    $('#question-container').removeClass('layout1 layout2 layout3')
    $('#question-container').addClass(layoutStr)
    window.layout = layoutStr
    previewQuestion()

wordWrap = (str, len=80, preserveInitialWhitespace=false, tabwidth=4) ->
    # the first character in each line is initial whitespace.  We don't want that joined with an
    # extra space character!
    joinLine = (line) ->
        return line[0] + line.slice(1).join(' ')

    paragraphs = str.split(/\n/)
    initialWhitespace = ''
    initialWhitespaceLen = 0
    initialWhitespaceCharLen = 0

    lines = []
    for p in paragraphs
        if preserveInitialWhitespace
            m = p.match(/^\s+/)
            if m
                initialWhitespace = m[0]
                initialWhitespaceCharLen = m[0].length
                # Find out how many tabs there are 'cause they count as 4 spaces
                numTabs = 0
                m = initialWhitespace.match(/\t/g)
                if m
                    numTabs = m.length
                initialWhitespaceLen = initialWhitespace.length + (tabwidth - 1)*numTabs
            else
                # if we have no whitespace at all, make sure we put back in the defaults
                initialWhitespace = ''
                initialWhitespaceLen = 0
                initialWhitespaceCharLen = 0

        # we have already measured the whitespace at the start of the line, so we should
        # split after that whitespace
        words = p.slice(initialWhitespaceCharLen).split(' ')
        line = [initialWhitespace] # preload our line with initial whitespace.  If preserveInitialWhitespace == false, initialWhitespace will be empty
        linelength = initialWhitespaceLen
        
        # for each word, either it fits on the end of the current line
        # or it becomes the start of the next line
        for w in words
            if linelength + w.length + 1 < len
                line.push w
                linelength += w.length + 1
            else
                lines.push joinLine(line)
                line = [initialWhitespace, w]
                linelength = initialWhitespaceLen + w.length
        # when we encounter the end of a paragraph, add a newline
        if line.length > 0
            lines.push joinLine(line)
        #lines.push '\n'
    return lines

# saves the current question and adds a thumbnail
saveQuestion = ->
    thumbnail = $('#math-preview').clone()
    thumbnail.css({'font-size':'.4em', 'display':'inline-block' })
    thumbnail.addClass('math-preview-thumbnail')
    $('#saved-questions').append(thumbnail)

createOptionEntries = (container, classes=[]) ->
    letters = ['A', 'B', 'C', 'D', 'E']
    for i in [0..4]
        s = "<div class='question-option'>" +
        "<span class='question-option-label'>(#{letters[i]})</span>" +
        "<span class='question-option-input-container'>" +
        "<input type='text' class='#{classes.join(' ')} option-#{i} question-option-input'/>" +
        "</span>" +
        "</div>"
        surround = $(s)
        container.append surround

previewQuestion = ->
    questiontitle = $('#question-title').val()
    questionbody = $('#question-body').val()
    options = []
    for opt in $('.question-option input')
        opt = $(opt)
        text = $.trim opt.val()
        options.push text if text.length > 0

    frameArgs =
        questiontitle: questiontitle
        questionbody: questionbody
        options: options
        layout: layout

    frame = new beamerFrame(frameArgs)
    window.currentFrame = frame
    frametext = frame.getText()

    $('#latex-preview').val(frametext)
    if window.codePreview
        window.codePreview.setValue(frametext)
    
    # Set up the preview area for the question
    $('#math-preview .title').text(questiontitle)
    $('#math-preview .body').text(questionbody)
    container = $('#math-preview .questions')
    container.empty()
    letters = ['A', 'B', 'C', 'D', 'E']
    for i in [0...options.length]
        surround = $("<span class='question-option'>(#{letters[i]}) 
        <span class='option-text option-#{i}'/>#{options[i]}</span>")
        container.append surround
        
    
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, $('#math-preview')[0]])
    
class beamerFrame
    _frameIn: '\\begin{frame}'
    _frameOut: '\\end{frame}'
    constructor: (options)->
            {@questiontitle} = options
            {@questionbody} = options
            {@options} = options
            {@layout} = options
    # returns the latex code for the question
    getText: ->
        enumerationLetters = ['(A)', '(B)', '(C)', '(D)', '(E)', '(F)']

        ret = [@_frameIn]
        ret.push "\t\\frametitle{#{@questiontitle}}" if @questiontitle

        console.log layout
        switch @layout
            when 'layout1'
                # Make sure the body text has tabs inserted
                if @questionbody
                    ret.push ''
                    lines = @questionbody.split('\n')
                    for l in lines
                        ret.push '\t'+l
                    ret.push ''
                    ret.push '\t\\vspace{.2em}'

                if @options and @options.length > 0
                    ret.push '\t'+'\\begin{columns}'
                    ret.push '\t'+'\\begin{column}{.5\\textwidth}'
                    
                    # handle the left column first
                    ret.push '\t\t\\begin{enumerate}'
                    for i in [0...@options.length] by 2
                        o = @options[i]
                        ret.push "\t\t\t\\item[#{enumerationLetters[i]}] #{o}"
                    ret.push '\t\t\\end{enumerate}'
                    
                    ret.push '\t'+'\\end{column}\\begin{column}{.5\\textwidth}'
                    
                    # handle the right column, but only if there is something to put
                    # in it
                    if @options.length >= 2
                        ret.push '\t\t\\begin{enumerate}'
                        for i in [1...@options.length] by 2
                            o = @options[i]
                            ret.push "\t\t\t\\item[#{enumerationLetters[i]}] #{o}"
                        ret.push '\t\t\\end{enumerate}'
                    
                    ret.push '\t'+'\\end{column}'
                    ret.push '\t'+'\\end{columns}'

            when 'layout2'
                # Make sure the body text has tabs inserted
                if @questionbody
                    ret.push ''
                    lines = @questionbody.split('\n')
                    for l in lines
                        ret.push '\t'+l
                    ret.push ''
                    ret.push '\t\\vspace{.2em}'

                if @options and @options.length > 0
                    ret.push '\t\\begin{enumerate}'
                    for i in [0...@options.length]
                        o = @options[i]
                        ret.push "\t\t\\item[#{enumerationLetters[i]}] #{o}"

                    ret.push '\t\\end{enumerate}'
            when 'layout3'
                ret.push '\t'+'\\begin{columns}'
                ret.push '\t'+'\\begin{column}{.5\\textwidth}'
                # Make sure the body text has tabs inserted
                if @questionbody
                    lines = @questionbody.split('\n')
                    for l in lines
                        ret.push '\t\t'+l
                ret.push '\t'+'\\end{column}\\begin{column}{.5\\textwidth}'

                if @options and @options.length > 0
                    ret.push '\t\t\\begin{enumerate}'
                    for i in [0...@options.length]
                        o = @options[i]
                        ret.push "\t\t\t\\item[#{enumerationLetters[i]}] #{o}"

                    ret.push '\t\t\\end{enumerate}'
                ret.push '\t'+'\\end{column}'
                ret.push '\t'+'\\end{columns}'
            else
                throw new Error("Unknown layout type #{layout}")

        ret.push @_frameOut

        return wordWrap(ret.join('\n'), 80, true, 4).join('\n')

        
