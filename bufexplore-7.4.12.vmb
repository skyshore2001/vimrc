" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin\bufexplorer.vim	[[[1
1290
"=============================================================================
"    Copyright: Copyright (c) 2001-2016, Jeff Lanzarotta
"               All rights reserved.
"
"               Redistribution and use in source and binary forms, with or
"               without modification, are permitted provided that the
"               following conditions are met:
"
"               * Redistributions of source code must retain the above
"                 copyright notice, this list of conditions and the following
"                 disclaimer.
"
"               * Redistributions in binary form must reproduce the above
"                 copyright notice, this list of conditions and the following
"                 disclaimer in the documentation and/or other materials
"                 provided with the distribution.
"
"               * Neither the name of the {organization} nor the names of its
"                 contributors may be used to endorse or promote products
"                 derived from this software without specific prior written
"                 permission.
"
"               THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
"               CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
"               INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
"               MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
"               DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
"               CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
"               SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
"               NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
"               LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
"               HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
"               CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
"               OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
"               EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" Name Of File: bufexplorer.vim
"  Description: Buffer Explorer Vim Plugin
"   Maintainer: Jeff Lanzarotta (delux256-vim at yahoo dot com)
" Last Changed: Friday, 30 September 2016
"      Version: See g:bufexplorer_version for version number.
"        Usage: This file should reside in the plugin directory and be
"               automatically sourced.
"
"               You may use the default keymappings of
"
"                 <Leader>be  - Opens BufExplorer
"                 <Leader>bt  - Toggles BufExplorer open or closed
"                 <Leader>bs  - Opens horizontally split window BufExplorer
"                 <Leader>bv  - Opens vertically split window BufExplorer
"
"               Or you can override the defaults and define your own mapping
"               in your vimrc file, for example:
"
"                   nnoremap <silent> <F11> :BufExplorer<CR>
"                   nnoremap <silent> <s-F11> :ToggleBufExplorer<CR>
"                   nnoremap <silent> <m-F11> :BufExplorerHorizontalSplit<CR>
"                   nnoremap <silent> <c-F11> :BufExplorerVerticalSplit<CR>
"
"               Or you can use
"
"                 ":BufExplorer"                - Opens BufExplorer
"                 ":ToggleBufExplorer"          - Opens/Closes BufExplorer
"                 ":BufExplorerHorizontalSplit" - Opens horizontally window BufExplorer
"                 ":BufExplorerVerticalSplit"   - Opens vertically split window BufExplorer
"
"               For more help see supplied documentation.
"      History: See supplied documentation.
"=============================================================================

" Exit quickly if already running or when 'compatible' is set. {{{1
if exists("g:bufexplorer_version") || &cp
    finish
endif
"1}}}

" Version number
let g:bufexplorer_version = "7.4.12"

" Plugin Code {{{1
" Check for Vim version {{{2
if v:version < 700
    echohl WarningMsg
    echo "Sorry, bufexplorer ".g:bufexplorer_version." required Vim 7.0 or greater."
    echohl None
    finish
endif
" Check to see if the version of Vim has the correct patch applied, if not, do
" not used <nowait>.
if v:version > 703 || v:version == 703 && has('patch1261') && has('patch1264')
    " We are good to go.
else
    echohl WarningMsg
    echo "Sorry, bufexplorer ".g:bufexplorer_version." required Vim 7.3 or greater with patch1261 and patch1264."
    echohl None
    finish
endif

" Create commands {{{2
command! BufExplorer :call BufExplorer()
command! ToggleBufExplorer :call ToggleBufExplorer()
command! BufExplorerHorizontalSplit :call BufExplorerHorizontalSplit()
command! BufExplorerVerticalSplit :call BufExplorerVerticalSplit()

" Set {{{2
function! s:Set(var, default)
    if !exists(a:var)
        if type(a:default)
            execute "let" a:var "=" string(a:default)
        else
            execute "let" a:var "=" a:default
        endif

        return 1
    endif

    return 0
endfunction

" Script variables {{{2
let s:MRU_Exclude_List = ["[BufExplorer]","__MRU_Files__"]
let s:MRUList = []
let s:name = '[BufExplorer]'
let s:originBuffer = 0
let s:running = 0
let s:sort_by = ["number", "name", "fullpath", "mru", "extension"]
let s:splitMode = ""
let s:types = {"fullname": ':p', "path": ':p:h', "relativename": ':~:.', "relativepath": ':~:.:h', "shortname": ':t'}

" Setup the autocommands that handle the MRUList and other stuff. {{{2
autocmd VimEnter * call s:Setup()

" Setup {{{2
function! s:Setup()
    call s:Reset()

    " Now that the MRUList is created, add the other autocmds.
    augroup BufExplorer
        autocmd!
        autocmd BufEnter,BufNew * call s:ActivateBuffer()
        autocmd BufWipeOut * call s:DeactivateBuffer(1)
        autocmd BufDelete * call s:DeactivateBuffer(0)
        autocmd BufWinEnter \[BufExplorer\] call s:Initialize()
        autocmd BufWinLeave \[BufExplorer\] call s:Cleanup()
    augroup END
endfunction

" Reset {{{2
function! s:Reset()
    " Build initial MRUList. This makes sure all the files specified on the
    " command line are picked up correctly.
    let s:MRUList = range(1, bufnr('$'))

    " Initialize the association of buffers to tabs for any buffers
    " that have been created prior to now, e.g., files specified as
    " vim command line arguments
    call s:CatalogBuffers()
endfunction

" CatalogBuffers {{{2
" Create tab associations for any existing buffers
function! s:CatalogBuffers()
    let ct = tabpagenr()

    for tab in range(1, tabpagenr('$'))
        silent execute 'normal! ' . tab . 'gt'
        for buf in tabpagebuflist()
            call s:UpdateTabBufData(buf)
        endfor
    endfor

    silent execute 'normal! ' . ct . 'gt'
endfunction

" AssociatedTab {{{2
" Return the number of the tab associated with the specified buffer.
" If the buffer is associated with more than one tab, the first one
" found is returned. If the buffer is not associated with any tabs,
" -1 is returned.
function! s:AssociatedTab(bufnr)
    for tab in range(1, tabpagenr('$'))
        let list = gettabvar(tab, 'bufexp_buf_list', [])
        let idx = index(list, a:bufnr)
        if idx != -1
            return tab
        endif
    endfor

    return -1
endfunction

" RemoveBufFromOtherTabs {{{2
" Remove the specified buffer from the buffer lists of all tabs
" except the current tab.
function! s:RemoveBufFromOtherTabs(bufnr)
    for tab in range(1, tabpagenr('$'))
        if tab == tabpagenr()
            continue
        endif

        let list = gettabvar(tab, 'bufexp_buf_list', [])
        let idx = index(list, a:bufnr)
        if idx == -1
            continue
        endif

        call remove(list, idx)
        call settabvar(tab, 'bufexp_buf_list', list)
    endfor
endfunction

" AddBufToCurrentTab {{{2
" Add the specified buffer to the list of buffers associated
" with the current tab
function! s:AddBufToCurrentTab(bufnr)
    if index(t:bufexp_buf_list, a:bufnr) == -1
        call add(t:bufexp_buf_list, a:bufnr)
    endif
endfunction

" IsInCurrentTab {{{2
" Returns whether the specified buffer is associated
" with the current tab
function! s:IsInCurrentTab(bufnr)
    " It shouldn't happen that the list of buffers is
    " not defined but if it does, play it safe and
    " include the buffer
    if !exists('t:bufexp_buf_list')
        return 1
    endif

    return (index(t:bufexp_buf_list, a:bufnr) != -1)
endfunction

" UpdateTabBufData {{{2
" Update the tab buffer data for the specified buffer
"
" The current tab's list is updated. If a buffer is only
" allowed to be associated with one tab, it is removed
" from the lists of any other tabs with which it may have
" been associated.
"
" The associations between tabs and buffers are maintained
" in separate lists for each tab, which are stored in tab-
" specific variables 't:bufexp_buf_list'.
function! s:UpdateTabBufData(bufnr)
    " The first time we add a tab, Vim uses the current buffer
    " as its starting page even though we are about to edit a
    " new page, and another BufEnter for the new page is triggered
    " later. Use this first BufEnter to initialize the list of
    " buffers, but don't add the buffer number to the list if
    " it is already associated with another tab
    "
    " Unfortunately, this doesn't work right when the first
    " buffer opened in the tab should be associated with it,
    " such as when 'tab split +buffer N' is used
    if !exists("t:bufexp_buf_list")
        let t:bufexp_buf_list = []

        if s:AssociatedTab(a:bufnr) != -1
            return
        endif
    endif

    call s:AddBufToCurrentTab(a:bufnr)

    if g:bufExplorerOnlyOneTab
        call s:RemoveBufFromOtherTabs(a:bufnr)
    endif
endfunction

" ActivateBuffer {{{2
function! s:ActivateBuffer()
    let _bufnr = bufnr("%")
    call s:UpdateTabBufData(_bufnr)
    call s:MRUPush(_bufnr)
endfunction

" DeactivateBuffer {{{2
function! s:DeactivateBuffer(remove)
    let _bufnr = str2nr(expand("<abuf>"))
    call s:MRUPop(_bufnr)
endfunction

" MRUPop {{{2
function! s:MRUPop(bufnr)
    call filter(s:MRUList, 'v:val != '.a:bufnr)
endfunction

" MRUPush {{{2
function! s:MRUPush(buf)
    " Skip temporary buffer with buftype set. Don't add the BufExplorer window
    " to the list.
    if s:ShouldIgnore(a:buf) == 1
        return
    endif

    " Remove the buffer number from the list if it already exists.
    call s:MRUPop(a:buf)

    " Add the buffer number to the head of the list.
    call insert(s:MRUList, a:buf)
endfunction

" ShouldIgnore {{{2
function! s:ShouldIgnore(buf)
    " Ignore temporary buffers with buftype set.
    if empty(getbufvar(a:buf, "&buftype") == 0)
        return 1
    endif

    " Ignore buffers with no name.
    if empty(bufname(a:buf)) == 1
        return 1
    endif

    " Ignore the BufExplorer buffer.
    if fnamemodify(bufname(a:buf), ":t") == s:name
        return 1
    endif

    " Ignore any buffers in the exclude list.
    if index(s:MRU_Exclude_List, bufname(a:buf)) >= 0
        return 1
    endif

    " Else return 0 to indicate that the buffer was not ignored.
    return 0
endfunction

" Initialize {{{2
function! s:Initialize()
    let s:_insertmode = &insertmode
    set noinsertmode

    let s:_showcmd = &showcmd
    set noshowcmd

    let s:_cpo = &cpo
    set cpo&vim

    let s:_report = &report
    let &report = 10000

    setlocal nonumber
    setlocal foldcolumn=0
    setlocal nofoldenable
    setlocal cursorline
    setlocal nospell

    setlocal nobuflisted

    let s:running = 1
endfunction

" Cleanup {{{2
function! s:Cleanup()
    if exists("s:_insertmode")
        let &insertmode = s:_insertmode
    endif

    if exists("s:_showcmd")
        let &showcmd = s:_showcmd
    endif

    if exists("s:_cpo")
        let &cpo = s:_cpo
    endif

    if exists("s:_report")
        let &report = s:_report
    endif

    let s:running = 0
    let s:splitMode = ""

    delmarks!
endfunction

" BufExplorerHorizontalSplit {{{2
function! BufExplorerHorizontalSplit()
    let s:splitMode = "sp"
    execute "BufExplorer"
endfunction

" BufExplorerVerticalSplit {{{2
function! BufExplorerVerticalSplit()
    let s:splitMode = "vsp"
    execute "BufExplorer"
endfunction

" ToggleBufExplorer {{{2
function! ToggleBufExplorer()
    if exists("s:running") && s:running == 1 && bufname(winbufnr(0)) == s:name
        call s:Close()
    else
        call BufExplorer()
    endif
endfunction

" BufExplorer {{{2
function! BufExplorer()
    let name = s:name

    if !has("win32")
        " On non-Windows boxes, escape the name so that is shows up correctly.
        let name = escape(name, "[]")
    endif

    " Make sure there is only one explorer open at a time.
    if s:running == 1
        " Go to the open buffer.
        if has("gui")
            execute "drop" name
        endif

        return
    endif

    " Add zero to ensure the variable is treated as a number.
    let s:originBuffer = bufnr("%") + 0

    silent let s:raw_buffer_listing = s:GetBufferInfo(0)

    " We may have to split the current window.
    if s:splitMode != ""
        " Save off the original settings.
        let [_splitbelow, _splitright] = [&splitbelow, &splitright]

        " Set the setting to ours.
        let [&splitbelow, &splitright] = [g:bufExplorerSplitBelow, g:bufExplorerSplitRight]
        let _size = (s:splitMode == "sp") ? g:bufExplorerSplitHorzSize : g:bufExplorerSplitVertSize

        " Split the window either horizontally or vertically.
        if _size <= 0
            execute 'keepalt ' . s:splitMode
        else
            execute 'keepalt ' . _size . s:splitMode
        endif

        " Restore the original settings.
        let [&splitbelow, &splitright] = [_splitbelow, _splitright]
    endif

    if !exists("b:displayMode") || b:displayMode != "winmanager"
        " Do not use keepalt when opening bufexplorer to allow the buffer that
        " we are leaving to become the new alternate buffer
        execute "silent keepjumps hide edit".name
    endif

    call s:DisplayBufferList()

    " Position the cursor in the newly displayed list on the line representing
    " the active buffer.  The active buffer is the line with the '%' character
    " in it.
    execute search("%")
endfunction

" DisplayBufferList {{{2
function! s:DisplayBufferList()
    " Do not set bufhidden since it wipes out the data if we switch away from
    " the buffer using CTRL-^.
    setlocal buftype=nofile
    setlocal modifiable
    setlocal noswapfile
    setlocal nowrap

    call s:SetupSyntax()
    call s:MapKeys()

    " Wipe out any existing lines in case BufExplorer buffer exists and the
    " user had changed any global settings that might reduce the number of
    " lines needed in the buffer.
    silent keepjumps 1,$d _

    call setline(1, s:CreateHelp())
    call s:BuildBufferList()
    call cursor(s:firstBufferLine, 1)

    if !g:bufExplorerResize
        normal! zz
    endif

    setlocal nomodifiable
endfunction

" MapKeys {{{2
function! s:MapKeys()
    if exists("b:displayMode") && b:displayMode == "winmanager"
        nnoremap <buffer> <silent> <tab> :call <SID>SelectBuffer()<CR>
    endif

    nnoremap <script> <silent> <nowait> <buffer> <2-leftmouse> :call <SID>SelectBuffer()<CR>
    nnoremap <script> <silent> <nowait> <buffer> <CR>          :call <SID>SelectBuffer()<CR>
    nnoremap <script> <silent> <nowait> <buffer> <F1>          :call <SID>ToggleHelp()<CR>
    nnoremap <script> <silent> <nowait> <buffer> <s-cr>        :call <SID>SelectBuffer("tab")<CR>
    nnoremap <script> <silent> <nowait> <buffer> B             :call <SID>ToggleOnlyOneTab()<CR>
    nnoremap <script> <silent> <nowait> <buffer> b             :call <SID>SelectBuffer("ask")<CR>
    nnoremap <script> <silent> <nowait> <buffer> d             :call <SID>RemoveBuffer("delete")<CR>
    xnoremap <script> <silent> <nowait> <buffer> d             :call <SID>RemoveBuffer("delete")<CR>
    nnoremap <script> <silent> <nowait> <buffer> D             :call <SID>RemoveBuffer("wipe")<CR>
    xnoremap <script> <silent> <nowait> <buffer> D             :call <SID>RemoveBuffer("wipe")<CR>
    nnoremap <script> <silent> <nowait> <buffer> f             :call <SID>ToggleFindActive()<CR>
    nnoremap <script> <silent> <nowait> <buffer> m             :call <SID>MRUListShow()<CR>
    nnoremap <script> <silent> <nowait> <buffer> o             :call <SID>SelectBuffer()<CR>
    nnoremap <script> <silent> <nowait> <buffer> p             :call <SID>ToggleSplitOutPathName()<CR>
    nnoremap <script> <silent> <nowait> <buffer> q             :call <SID>Close()<CR>
    nnoremap <script> <silent> <nowait> <buffer> r             :call <SID>SortReverse()<CR>
    nnoremap <script> <silent> <nowait> <buffer> R             :call <SID>ToggleShowRelativePath()<CR>
    nnoremap <script> <silent> <nowait> <buffer> s             :call <SID>SortSelect()<CR>
    nnoremap <script> <silent> <nowait> <buffer> S             :call <SID>ReverseSortSelect()<CR>
    nnoremap <script> <silent> <nowait> <buffer> t             :call <SID>SelectBuffer("tab")<CR>
    nnoremap <script> <silent> <nowait> <buffer> T             :call <SID>ToggleShowTabBuffer()<CR>
    nnoremap <script> <silent> <nowait> <buffer> u             :call <SID>ToggleShowUnlisted()<CR>

    for k in ["G", "n", "N", "L", "M", "H"]
        execute "nnoremap <buffer> <silent>" k ":keepjumps normal!" k."<CR>"
    endfor
endfunction

" SetupSyntax {{{2
function! s:SetupSyntax()
    if has("syntax")
        syn match bufExplorerHelp     "^\".*" contains=bufExplorerSortBy,bufExplorerMapping,bufExplorerTitle,bufExplorerSortType,bufExplorerToggleSplit,bufExplorerToggleOpen
        syn match bufExplorerOpenIn   "Open in \w\+ window" contained
        syn match bufExplorerSplit    "\w\+ split" contained
        syn match bufExplorerSortBy   "Sorted by .*" contained contains=bufExplorerOpenIn,bufExplorerSplit
        syn match bufExplorerMapping  "\" \zs.\+\ze :" contained
        syn match bufExplorerTitle    "Buffer Explorer.*" contained
        syn match bufExplorerSortType "'\w\{-}'" contained
        syn match bufExplorerBufNbr   /^\s*\d\+/
        syn match bufExplorerToggleSplit  "toggle split type" contained
        syn match bufExplorerToggleOpen   "toggle open mode" contained

        syn match bufExplorerModBuf    /^\s*\d\+.\{4}+.*/
        syn match bufExplorerLockedBuf /^\s*\d\+.\{3}[\-=].*/
        syn match bufExplorerHidBuf    /^\s*\d\+.\{2}h.*/
        syn match bufExplorerActBuf    /^\s*\d\+.\{2}a.*/
        syn match bufExplorerCurBuf    /^\s*\d\+.%.*/
        syn match bufExplorerAltBuf    /^\s*\d\+.#.*/
        syn match bufExplorerUnlBuf    /^\s*\d\+u.*/
        syn match bufExplorerInactBuf  /^\s*\d\+ \{7}.*/

        hi def link bufExplorerBufNbr Number
        hi def link bufExplorerMapping NonText
        hi def link bufExplorerHelp Special
        hi def link bufExplorerOpenIn Identifier
        hi def link bufExplorerSortBy String
        hi def link bufExplorerSplit NonText
        hi def link bufExplorerTitle NonText
        hi def link bufExplorerSortType bufExplorerSortBy
        hi def link bufExplorerToggleSplit bufExplorerSplit
        hi def link bufExplorerToggleOpen bufExplorerOpenIn

        hi def link bufExplorerActBuf Identifier
        hi def link bufExplorerAltBuf String
        hi def link bufExplorerCurBuf Type
        hi def link bufExplorerHidBuf Constant
        hi def link bufExplorerLockedBuf Special
        hi def link bufExplorerModBuf Exception
        hi def link bufExplorerUnlBuf Comment
        hi def link bufExplorerInactBuf Comment
    endif
endfunction

" ToggleHelp {{{2
function! s:ToggleHelp()
    let g:bufExplorerDetailedHelp = !g:bufExplorerDetailedHelp

    setlocal modifiable

    " Save position.
    normal! ma

    " Remove old header.
    if s:firstBufferLine > 1
        execute "keepjumps 1,".(s:firstBufferLine - 1) "d _"
    endif

    call append(0, s:CreateHelp())

    silent! normal! g`a
    delmarks a

    setlocal nomodifiable

    if exists("b:displayMode") && b:displayMode == "winmanager"
        call WinManagerForceReSize("BufExplorer")
    endif
endfunction

" GetHelpStatus {{{2
function! s:GetHelpStatus()
    let ret = '" Sorted by '.((g:bufExplorerReverseSort == 1) ? "reverse " : "").g:bufExplorerSortBy
    let ret .= ' | '.((g:bufExplorerFindActive == 0) ? "Don't " : "")."Locate buffer"
    let ret .= ((g:bufExplorerShowUnlisted == 0) ? "" : " | Show unlisted")
    let ret .= ((g:bufExplorerShowTabBuffer == 0) ? "" : " | Show buffers/tab")
    let ret .= ((g:bufExplorerOnlyOneTab == 0) ? "" : " | One tab/buffer")
    let ret .= ' | '.((g:bufExplorerShowRelativePath == 0) ? "Absolute" : "Relative")
    let ret .= ' '.((g:bufExplorerSplitOutPathName == 0) ? "Full" : "Split")." path"

    return ret
endfunction

" CreateHelp {{{2
function! s:CreateHelp()
    if g:bufExplorerDefaultHelp == 0 && g:bufExplorerDetailedHelp == 0
        let s:firstBufferLine = 1
        return []
    endif

    let header = []

    if g:bufExplorerDetailedHelp == 1
        call add(header, '" Buffer Explorer ('.g:bufexplorer_version.')')
        call add(header, '" --------------------------')
        call add(header, '" <F1> : toggle this help')
        call add(header, '" <enter> or o or Mouse-Double-Click : open buffer under cursor')
        call add(header, '" <shift-enter> or t : open buffer in another tab')
        call add(header, '" B : toggle if to save/use recent tab or not')
        call add(header, '" d : delete buffer')
        call add(header, '" D : wipe buffer')
        call add(header, '" f : toggle find active buffer')
        call add(header, '" p : toggle splitting of file and path name')
        call add(header, '" q : quit')
        call add(header, '" r : reverse sort')
        call add(header, '" R : toggle showing relative or full paths')
        call add(header, '" s : cycle thru "sort by" fields '.string(s:sort_by).'')
        call add(header, '" S : reverse cycle thru "sort by" fields')
        call add(header, '" T : toggle if to show only buffers for this tab or not')
        call add(header, '" u : toggle showing unlisted buffers')
    else
        call add(header, '" Press <F1> for Help')
    endif

    if (!exists("b:displayMode") || b:displayMode != "winmanager") || (b:displayMode == "winmanager" && g:bufExplorerDetailedHelp == 1)
        call add(header, s:GetHelpStatus())
        call add(header, '"=')
    endif

    let s:firstBufferLine = len(header) + 1

    return header
endfunction

" GetBufferInfo {{{2
function! s:GetBufferInfo(bufnr)
    redir => bufoutput

    " Show all buffers including the unlisted ones. [!] tells Vim to show the
    " unlisted ones.
    buffers!
    redir END

    if a:bufnr > 0
        " Since we are only interested in this specified buffer
        " remove the other buffers listed
        let bufoutput = substitute(bufoutput."\n", '^.*\n\(\s*'.a:bufnr.'\>.\{-}\)\n.*', '\1', '')
    endif

    let [all, allwidths, listedwidths] = [[], {}, {}]

    for n in keys(s:types)
        let allwidths[n] = []
        let listedwidths[n] = []
    endfor

    " Loop over each line in the buffer.
    for buf in split(bufoutput, '\n')
        let bits = split(buf, '"')

        " Use first and last components after the split on '"', in case a
        " filename with an embedded '"' is present.
        let b = {"attributes": bits[0], "line": substitute(bits[-1], '\s*', '', '')}

        let name = bufname(str2nr(b.attributes))
        let b["hasNoName"] = empty(name)
        if b.hasNoName
            let name = "[No Name]"
        endif

        for [key, val] in items(s:types)
            let b[key] = fnamemodify(name, val)
        endfor

        if getftype(b.fullname) == "dir" && g:bufExplorerShowDirectories == 1
            let b.shortname = "<DIRECTORY>"
        endif

        call add(all, b)

        for n in keys(s:types)
            call add(allwidths[n], s:StringWidth(b[n]))

            if b.attributes !~ "u"
                call add(listedwidths[n], s:StringWidth(b[n]))
            endif
        endfor
    endfor

    let [s:allpads, s:listedpads] = [{}, {}]

    for n in keys(s:types)
        let s:allpads[n] = repeat(' ', max(allwidths[n]))
        let s:listedpads[n] = repeat(' ', max(listedwidths[n]))
    endfor

    return all
endfunction

" BuildBufferList {{{2
function! s:BuildBufferList()
    let lines = []

    " Loop through every buffer.
    for buf in s:raw_buffer_listing
        " Skip unlisted buffers if we are not to show them.
        if !g:bufExplorerShowUnlisted && buf.attributes =~ "u"
            " Skip unlisted buffers if we are not to show them.
            continue
        endif

        " Skip "No Name" buffers if we are not to show them.
        if g:bufExplorerShowNoName == 0 && buf.hasNoName
            continue
        endif

        " Are we to show only buffer(s) for this tab?
        if g:bufExplorerShowTabBuffer && (!s:IsInCurrentTab(str2nr(buf.attributes)))
            continue
        endif

        let line = buf.attributes." "

        " Are we to split the path and file name?
        if g:bufExplorerSplitOutPathName
            let type = (g:bufExplorerShowRelativePath) ? "relativepath" : "path"
            let path = buf[type]
            let pad  = (g:bufExplorerShowUnlisted) ? s:allpads.shortname : s:listedpads.shortname
            let line .= buf.shortname." ".strpart(pad.path, s:StringWidth(buf.shortname))
        else
            let type = (g:bufExplorerShowRelativePath) ? "relativename" : "fullname"
            let path = buf[type]
            let line .= path
        endif

        let pads = (g:bufExplorerShowUnlisted) ? s:allpads : s:listedpads

        if !empty(pads[type])
            let line .= strpart(pads[type], s:StringWidth(path))." "
        endif

        let line .= buf.line

        call add(lines, line)
    endfor

    call setline(s:firstBufferLine, lines)
    call s:SortListing()
endfunction

" SelectBuffer {{{2
function! s:SelectBuffer(...)
    " Sometimes messages are not cleared when we get here so it looks like an
    " error has occurred when it really has not.
    "echo ""

    let _bufNbr = -1

    if (a:0 == 1) && (a:1 == "ask")
        " Ask the user for input.
        call inputsave()
        let cmd = input("Enter buffer number to switch to: ")
        call inputrestore()

        " Clear the message area from the previous prompt.
        redraw | echo

        if strlen(cmd) > 0
            let _bufNbr = str2nr(cmd)
        else
            call s:Error("Invalid buffer number, try again.")
            return
        endif
    else
        " Are we on a line with a file name?
        if line('.') < s:firstBufferLine
            execute "normal! \<CR>"
            return
        endif

        let _bufNbr = str2nr(getline('.'))

        " Check and see if we are running BufferExplorer via WinManager.
        if exists("b:displayMode") && b:displayMode == "winmanager"
            let _bufName = expand("#"._bufNbr.":p")

            if (a:0 == 1) && (a:1 == "tab")
                call WinManagerFileEdit(_bufName, 1)
            else
                call WinManagerFileEdit(_bufName, 0)
            endif

            return
        endif
    endif

    if bufexists(_bufNbr)
        if bufnr("#") == _bufNbr && !exists("g:bufExplorerChgWin")
            return s:Close()
        endif

        " Are we suppose to open the selected buffer in a tab?
        if (a:0 == 1) && (a:1 == "tab")
            " Yes, we are to open the selected buffer in a tab.

            " Restore [BufExplorer] buffer.
            execute "silent buffer!".s:originBuffer

            " Get the tab number where this buffer is located in.
            let tabNbr = s:GetTabNbr(_bufNbr)

            " Was the tab found?
            if tabNbr == 0
                " _bufNbr is not opened in any tabs. Open a new tab with the selected buffer in it.
                execute "999tab split +buffer" . _bufNbr
                " Workaround for the issue mentioned in UpdateTabBufData
                call s:UpdateTabBufData(_bufNbr)
            else
                " The _bufNbr is already opened in a tab, go to that tab.
                execute tabNbr . "tabnext"

                " Focus window.
                execute s:GetWinNbr(tabNbr, _bufNbr) . "wincmd w"
            endif
        else
            " No, the user did not ask to open the selected buffer in a tab.

            " Are we suppose to move to the tab where the active buffer is?
            if exists("g:bufExplorerChgWin")
                execute g:bufExplorerChgWin."wincmd w"
            elseif bufloaded(_bufNbr) && g:bufExplorerFindActive
                if g:bufExplorerFindActive
                    call s:Close()
                endif

                " Get the tab number where this buffer is located in.
                let tabNbr = s:GetTabNbr(_bufNbr)

                " Was the tab found?
                if tabNbr != 0
                    " Yes, the buffer is located in a tab. Go to that tab number.
                    execute tabNbr . "tabnext"
                else
                    "Nope, the buffer is not in a tab. Simply switch to that
                    "buffer.
                    let _bufName = expand("#"._bufNbr.":p")
                    execute _bufName ? "drop ".escape(_bufName, " ") : "buffer "._bufNbr
                endif
            endif

            " Switch to the selected buffer.
            execute "keepalt silent b!" _bufNbr
        endif

        " Make the buffer 'listed' again.
        call setbufvar(_bufNbr, "&buflisted", "1")

        " Call any associated function references. g:bufExplorerFuncRef may be
        " an individual function reference or it may be a list containing
        " function references. It will ignore anything that's not a function
        " reference.
        "
        " See  :help FuncRef  for more on function references.
        if exists("g:BufExplorerFuncRef")
            if type(g:BufExplorerFuncRef) == 2
                keepj call g:BufExplorerFuncRef()
            elseif type(g:BufExplorerFuncRef) == 3
                for FncRef in g:BufExplorerFuncRef
                    if type(FncRef) == 2
                        keepj call FncRef()
                    endif
                endfor
            endif
        endif
    else
        call s:Error("Sorry, that buffer no longer exists, please select another")
        call s:DeleteBuffer(_bufNbr, "wipe")
    endif
endfunction

" RemoveBuffer {{{2
function! s:RemoveBuffer(mode)
    " Are we on a line with a file name?
    if line('.') < s:firstBufferLine
        return
    endif

    " Do not allow this buffer to be deleted if it is the last one.
    if len(s:MRUList) == 1
        call s:Error("Sorry, you are not allowed to delete the last buffer")
        return
    endif

    " These commands are to temporarily suspend the activity of winmanager.
    if exists("b:displayMode") && b:displayMode == "winmanager"
        call WinManagerSuspendAUs()
    end

    let _bufNbr = str2nr(getline('.'))

    if getbufvar(_bufNbr, '&modified') == 1
        call s:Error("Sorry, no write since last change for buffer "._bufNbr.", unable to delete")
        return
    else
        " Okay, everything is good, delete or wipe the buffer.
        call s:DeleteBuffer(_bufNbr, a:mode)
    endif

    " Reactivate winmanager autocommand activity.
    if exists("b:displayMode") && b:displayMode == "winmanager"
        call WinManagerForceReSize("BufExplorer")
        call WinManagerResumeAUs()
    end
endfunction

" DeleteBuffer {{{2
function! s:DeleteBuffer(buf, mode)
    " This routine assumes that the buffer to be removed is on the current line.
    try
        " Wipe/Delete buffer from Vim.
        if a:mode == "wipe"
            execute "silent bwipe" a:buf
        else
            execute "silent bdelete" a:buf
        endif

        " Delete the buffer from the list on screen.
        setlocal modifiable
        normal! "_dd
        setlocal nomodifiable

        " Delete the buffer from the raw buffer list.
        call filter(s:raw_buffer_listing, 'v:val.attributes !~ " '.a:buf.' "')
    catch
        call s:Error(v:exception)
    endtry
endfunction

" ListedAndCurrentTab {{{2
" Returns whether the specified buffer is both listed and associated
" with the current tab
function! s:ListedAndCurrentTab(buf)
    return buflisted(a:buf) && s:IsInCurrentTab(a:buf)
endfunction

" Close {{{2
function! s:Close()
    " Get only the listed buffers associated with the current tab
    let listed = filter(copy(s:MRUList), "s:ListedAndCurrentTab(v:val)")
    if len(listed) == 0
        let listed = filter(range(1, bufnr('$')), "s:ListedAndCurrentTab(v:val)")
    endif

    " If we needed to split the main window, close the split one.
    if s:splitMode != "" && bufwinnr(s:originBuffer) != -1
        execute "wincmd c"
    endif

    " Check to see if there are anymore buffers listed.
    if len(listed) == 0
        " Since there are no buffers left to switch to, open a new empty
        " buffers.
        execute "enew"
    else
        " Since there are buffers left to switch to, switch to the previous and
        " then the current.
        for b in reverse(listed[0:1])
            execute "keepjumps silent b ".b
        endfor
    endif

    " Clear any messages.
    echo
endfunction

" ToggleSplitOutPathName {{{2
function! s:ToggleSplitOutPathName()
    let g:bufExplorerSplitOutPathName = !g:bufExplorerSplitOutPathName
    call s:RebuildBufferList()
    call s:UpdateHelpStatus()
endfunction

" ToggleShowRelativePath {{{2
function! s:ToggleShowRelativePath()
    let g:bufExplorerShowRelativePath = !g:bufExplorerShowRelativePath
    call s:RebuildBufferList()
    call s:UpdateHelpStatus()
endfunction

" ToggleShowTabBuffer {{{2
function! s:ToggleShowTabBuffer()
    let g:bufExplorerShowTabBuffer = !g:bufExplorerShowTabBuffer
    call s:RebuildBufferList(g:bufExplorerShowTabBuffer)
    call s:UpdateHelpStatus()
endfunction

" ToggleOnlyOneTab {{{2
function! s:ToggleOnlyOneTab()
    let g:bufExplorerOnlyOneTab = !g:bufExplorerOnlyOneTab
    call s:RebuildBufferList()
    call s:UpdateHelpStatus()
endfunction

" ToggleShowUnlisted {{{2
function! s:ToggleShowUnlisted()
    let g:bufExplorerShowUnlisted = !g:bufExplorerShowUnlisted
    let num_bufs = s:RebuildBufferList(g:bufExplorerShowUnlisted == 0)
    call s:UpdateHelpStatus()
endfunction

" ToggleFindActive {{{2
function! s:ToggleFindActive()
    let g:bufExplorerFindActive = !g:bufExplorerFindActive
    call s:UpdateHelpStatus()
endfunction

" RebuildBufferList {{{2
function! s:RebuildBufferList(...)
    setlocal modifiable

    let curPos = getpos('.')

    if a:0 && a:000[0] && (line('$') >= s:firstBufferLine)
        " Clear the list first.
        execute "silent keepjumps ".s:firstBufferLine.',$d _'
    endif

    let num_bufs = s:BuildBufferList()

    call setpos('.', curPos)

    setlocal nomodifiable

    return num_bufs
endfunction

" UpdateHelpStatus {{{2
function! s:UpdateHelpStatus()
    setlocal modifiable

    let text = s:GetHelpStatus()
    call setline(s:firstBufferLine - 2, text)

    setlocal nomodifiable
endfunction

" MRUCmp {{{2
function! s:MRUCmp(line1, line2)
    return index(s:MRUList, str2nr(a:line1)) - index(s:MRUList, str2nr(a:line2))
endfunction

" SortReverse {{{2
function! s:SortReverse()
    let g:bufExplorerReverseSort = !g:bufExplorerReverseSort
    call s:ReSortListing()
endfunction

" SortSelect {{{2
function! s:SortSelect()
    let g:bufExplorerSortBy = get(s:sort_by, index(s:sort_by, g:bufExplorerSortBy) + 1, s:sort_by[0])
    call s:ReSortListing()
endfunction

" ReverseSortSelect {{{2
function! s:ReverseSortSelect()
    let g:bufExplorerSortBy = get(s:sort_by, index(s:sort_by, g:bufExplorerSortBy) - 1, s:sort_by[-1])
    call s:ReSortListing()
endfunction

" ReSortListing {{{2
function! s:ReSortListing()
    setlocal modifiable

    let curPos = getpos('.')

    call s:SortListing()
    call s:UpdateHelpStatus()

    call setpos('.', curPos)

    setlocal nomodifiable
endfunction

" SortListing {{{2
function! s:SortListing()
    let sort = s:firstBufferLine.",$sort".((g:bufExplorerReverseSort == 1) ? "!": "")

    if g:bufExplorerSortBy == "number"
        " Easiest case.
        execute sort 'n'
    elseif g:bufExplorerSortBy == "name"
        " Sort by full path first
        execute sort 'ir /\zs\f\+\ze\s\+line/'

        if g:bufExplorerSplitOutPathName
            execute sort 'ir /\d.\{7}\zs\f\+\ze/'
        else
            execute sort 'ir /\zs[^\/\\]\+\ze\s*line/'
        endif
    elseif g:bufExplorerSortBy == "fullpath"
        if g:bufExplorerSplitOutPathName
            " Sort twice - first on the file name then on the path.
            execute sort 'ir /\d.\{7}\zs\f\+\ze/'
        endif

        execute sort 'ir /\zs\f\+\ze\s\+line/'
    elseif g:bufExplorerSortBy == "extension"
        " Sort by full path...
        execute sort 'ir /\zs\f\+\ze\s\+line/'

        " Sort by name...
        if g:bufExplorerSplitOutPathName
            " Sort twice - first on the file name then on the path.
            execute sort 'ir /\d.\{7}\zs\f\+\ze/'
        endif

        " Sort by extension.
        execute sort 'ir /\.\zs\w\+\ze\s/'
    elseif g:bufExplorerSortBy == "mru"
        let l = getline(s:firstBufferLine, "$")

        call sort(l, "<SID>MRUCmp")

        if g:bufExplorerReverseSort
            call reverse(l)
        endif

        call setline(s:firstBufferLine, l)
    endif
endfunction

" MRUListShow {{{2
function! s:MRUListShow()
    echomsg "MRUList=".string(s:MRUList)
endfunction

" Error {{{2
" Display a message using ErrorMsg highlight group.
function! s:Error(msg)
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

" Warning {{{2
" Display a message using WarningMsg highlight group.
function! s:Warning(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

" GetTabNbr {{{2
function! s:GetTabNbr(bufNbr)
    " Searching buffer bufno, in tabs.
    for i in range(tabpagenr("$"))
        if index(tabpagebuflist(i + 1), a:bufNbr) != -1
            return i + 1
        endif
    endfor

    return 0
endfunction

" GetWinNbr" {{{2
function! s:GetWinNbr(tabNbr, bufNbr)
    " window number in tabpage.
    let tablist = tabpagebuflist(a:tabNbr)
    " Number:     0
    " String:     1
    " Funcref:    2
    " List:       3
    " Dictionary: 4
    " Float:      5
    if type(tablist) == 3
        return index(tabpagebuflist(a:tabNbr), a:bufNbr) + 1
    else
        return 1
    endif
endfunction

" StringWidth" {{{2
if exists('*strwidth')
    function s:StringWidth(s)
        return strwidth(a:s)
    endfunction
else
    function s:StringWidth(s)
        return len(a:s)
    endfunction
endif

" Winmanager Integration {{{2
let g:BufExplorer_title = "\[Buf\ List\]"
call s:Set("g:bufExplorerResize", 1)
call s:Set("g:bufExplorerMaxHeight", 25) " Handles dynamic resizing of the window.

" function! to start display. Set the mode to 'winmanager' for this buffer.
" This is to figure out how this plugin was called. In a standalone fashion
" or by winmanager.
function! BufExplorer_Start()
    let b:displayMode = "winmanager"
    call BufExplorer()
endfunction

" Returns whether the display is okay or not.
function! BufExplorer_IsValid()
    return 0
endfunction

" Handles dynamic refreshing of the window.
function! BufExplorer_Refresh()
    let b:displayMode = "winmanager"
    call BufExplorer()
endfunction

function! BufExplorer_ReSize()
    if !g:bufExplorerResize
        return
    end

    let nlines = min([line("$"), g:bufExplorerMaxHeight])

    execute nlines." wincmd _"

    " The following lines restore the layout so that the last file line is also
    " the last window line. Sometimes, when a line is deleted, although the
    " window size is exactly equal to the number of lines in the file, some of
    " the lines are pushed up and we see some lagging '~'s.
    let pres = getpos(".")

    normal! $

    let _scr = &scrolloff
    let &scrolloff = 0

    normal! z-

    let &scrolloff = _scr

    call setpos(".", pres)
endfunction

" Default values {{{2
call s:Set("g:bufExplorerDisableDefaultKeyMapping", 0)  " Do not disable default key mappings.
call s:Set("g:bufExplorerDefaultHelp", 1)               " Show default help?
call s:Set("g:bufExplorerDetailedHelp", 0)              " Show detailed help?
call s:Set("g:bufExplorerFindActive", 1)                " When selecting an active buffer, take you to the window where it is active?
call s:Set("g:bufExplorerOnlyOneTab", 1)                " If ShowTabBuffer = 1, only store the most recent tab for this buffer.
call s:Set("g:bufExplorerReverseSort", 0)               " Sort in reverse order by default?
call s:Set("g:bufExplorerShowDirectories", 1)           " (Dir's are added by commands like ':e .')
call s:Set("g:bufExplorerShowRelativePath", 0)          " Show listings with relative or absolute paths?
call s:Set("g:bufExplorerShowTabBuffer", 0)             " Show only buffer(s) for this tab?
call s:Set("g:bufExplorerShowUnlisted", 0)              " Show unlisted buffers?
call s:Set("g:bufExplorerShowNoName", 0)                " Show 'No Name' buffers?
call s:Set("g:bufExplorerSortBy", "mru")                " Sorting methods are in s:sort_by:
call s:Set("g:bufExplorerSplitBelow", &splitbelow)      " Should horizontal splits be below or above current window?
call s:Set("g:bufExplorerSplitOutPathName", 1)          " Split out path and file name?
call s:Set("g:bufExplorerSplitRight", &splitright)      " Should vertical splits be on the right or left of current window?
call s:Set("g:bufExplorerSplitVertSize", 0)             " Height for a vertical split. If <=0, default Vim size is used.
call s:Set("g:bufExplorerSplitHorzSize", 0)             " Height for a horizontal split. If <=0, default Vim size is used.

" Default key mapping {{{2
if !hasmapto('BufExplorer') && g:bufExplorerDisableDefaultKeyMapping == 0
    nnoremap <script> <silent> <unique> <Leader>be :BufExplorer<CR>
endif

if !hasmapto('ToggleBufExplorer') && g:bufExplorerDisableDefaultKeyMapping == 0
    nnoremap <script> <silent> <unique> <Leader>bt :ToggleBufExplorer<CR>
endif

if !hasmapto('BufExplorerHorizontalSplit') && g:bufExplorerDisableDefaultKeyMapping == 0
    nnoremap <script> <silent> <unique> <Leader>bs :BufExplorerHorizontalSplit<CR>
endif

if !hasmapto('BufExplorerVerticalSplit') && g:bufExplorerDisableDefaultKeyMapping == 0
    nnoremap <script> <silent> <unique> <Leader>bv :BufExplorerVerticalSplit<CR>
endif

" vim:ft=vim foldmethod=marker sw=4
doc\bufexplorer.txt	[[[1
762
*bufexplorer.txt*              Buffer Explorer       Last Change: 30 Sep 2016

Buffer Explorer                                *buffer-explorer* *bufexplorer*
                                Version 7.4.12

Plugin for easily exploring (or browsing) Vim|:buffers|.

|bufexplorer-installation|   Installation
|bufexplorer-usage|          Usage
|bufexplorer-windowlayout|   Window Layout
|bufexplorer-customization|  Customization
|bufexplorer-changelog|      Change Log
|bufexplorer-todo|           Todo
|bufexplorer-credits|        Credits
|bufexplorer-copyright|      Copyright

For Vim version 7.0 and above.
This plugin is only available if 'compatible' is not set.

{Vi does not have any of this}

==============================================================================
INSTALLATION                                        *bufexplorer-installation*

To install:
  - Download the bufexplorer.zip from one of the following places:
    https://github.com/jlanzarotta/bufexplorer
    http://www.vim.org/scripts/script.php?script_id=42
    or use a package manager like Vundle.
  - Extract the zip archive into your runtime directory.
    The archive contains plugin/bufexplorer.vim, and doc/bufexplorer.txt.
  - Start Vim or goto an existing instance of Vim.
  - Execute the following command:
>
      :helptag <your runtime directory>/doc
<
    This will generate all the help tags for any file located in the doc
    directory.

==============================================================================
USAGE                                                      *bufexplorer-usage*

To start exploring in the current window, use: >
 <Leader>be   or   :BufExplorer   or   Your custom key mapping
To toggle bufexplorer on or off in the current window, use: >
 <Leader>bt   or   :ToggleBufExplorer   or   Your custom key mapping
To start exploring in a newly split horizontal window, use: >
 <Leader>bs   or   :BufExplorerHorizontalSplit   or   Your custom key mapping
To start exploring in a newly split vertical window, use: >
 <Leader>bv   or   :BufExplorerVerticalSplit   or   Your custom key mapping

If you would like to use something other than the default leader key - '\' -
you may simply change the leader (see |mapleader|).

When <Leader>bs or <Leader>bv is issued, bufexplorer opens in either a
horizontally or vertically split window.  By issusing either of these commands,
the user is telling bufexplorer that they want to split the window and have
bufexplorer show the buffer they are about to select (from the bufexplorer
windows) in the newly split window.  When <Leader>be is issued, bufexplorer
opens the bufexplorer contents in the current window and the buffer the user
selects is opened in the current window.

Note: If the current buffer is modified when bufexplorer started, the current
      window is always split and the new bufexplorer is displayed in that new
      window.

Commands to use once exploring:

 <F1>          Toggle help information.
 <enter>       Opens the buffer that is under the cursor into the current
               window.
 <leftmouse>   Opens the buffer that is under the cursor into the current
               window.
 <shift-enter> Opens the buffer that is under the cursor in another tab.
 b             Fast buffer switching with b<any bufnum>.
 B             Works in association with the |ShowTabBuffer| option.  If
               |ShowTabBuffer| is set to 1, this toggles if BufExplorer is to
               only store the most recent tab for this buffer or not.
 d             |:delete| the buffer under the cursor from the list.  The
               buffer's 'buflisted' is cleared. This allows for the buffer to
               be displayed again using the 'show unlisted' command.
 D             |:wipeout| the buffer under the cursor from the list.  When a
               buffer is wiped, it will not be shown when unlisted buffers are
               displayed.
 f             Toggles whether you are taken to the active window when
               selecting a buffer or not.
 o             Opens the buffer that is under the cursor into the current
               window.
 p             Toggles the showing of a split filename/pathname.
 q             Exit/Close bufexplorer.
 r             Reverses the order the buffers are listed in.
 R             Toggles relative path/absolute path.
 s             Cycle thru how the buffers are listed. Either by buffer
               number, file name, file extension, most recently used (MRU), or
               full path.
 S             Cycle thru how the buffers are listed, in reverse order.
               Either by buffer number, file name, file extension, most
               recently used (MRU), or full path.
 t             Opens the buffer that is under the cursor in another tab.
 T             Toggles to show only buffers for this tab or not.
 u             Toggles the showing of "unlisted" buffers.

Once invoked, Buffer Explorer displays a sorted list (MRU is the default
sort method) of all the buffers that are currently opened. You are then
able to move the cursor to the line containing the buffer's name you are
wanting to act upon. Once you have selected the buffer you would like,
you can then either open it, close it (delete), resort the list, reverse
the sort, quit exploring and so on...

===============================================================================
WINDOW LAYOUT                                       *bufexplorer-windowlayout*

-------------------------------------------------------------------------------
" Press <F1> for Help
" Sorted by mru | Locate buffer | Absolute Split path
"=
  1 %a    bufexplorer.txt      C:\Vim\vimfiles\doc       line 87
  2 #     bufexplorer.vim      c:\Vim\vimfiles\plugin    line 1
-------------------------------------------------------------------------------
  | |     |                    |                         |
  | |     |                    |                         +-- Current Line #.
  | |     |                    +-- Relative/Full Path
  | |     +-- Buffer Name.
  | +-- Buffer Attributes. See |:buffers| for more information.
  +-- Buffer Number. See |:buffers| for more information.

===============================================================================
CUSTOMIZATION                                       *bufexplorer-customization*

If you do not like the default key mappings of <Leader>be, <Leader>bs, and
<Leader>bv, you can override bufexplorer's default mappings by setting up
something like the following in your vimrc file:

  nnoremap <silent> <F11> :BufExplorer<CR>
  nnoremap <silent> <s-F11> :ToggleBufExplorer<CR>
  nnoremap <silent> <m-F11> :BufExplorerHorizontalSplit<CR>
  nnoremap <silent> <c-F11> :BufExplorerVerticalSplit<CR>

                                                          *g:bufExplorerChgWin*
If set, bufexplorer will bring up the selected buffer in the window specified
by g:bufExplorerChgWin.

                                                     *g:bufExplorerDefaultHelp*
To control whether the default help is displayed or not, use: >
  let g:bufExplorerDefaultHelp=0       " Do not show default help.
  let g:bufExplorerDefaultHelp=1       " Show default help.
The default is to show the default help.

                                        *g:bufExplorerDisableDefaultKeyMapping*
To control whether the default key mappings are enabled or not, use: >
  let g:bufExplorerDisableDefaultKeyMapping=0    " Do not disable mapping.
  let g:bufExplorerDisableDefaultKeyMapping=1    " Disable mapping.
The default is NOT to disable the default key mapping.

                                                    *g:bufExplorerDetailedHelp*
To control whether detailed help is display by, use: >
  let g:bufExplorerDetailedHelp=0      " Do not show detailed help.
  let g:bufExplorerDetailedHelp=1      " Show detailed help.
The default is NOT to show detailed help.

                                                      *g:bufExplorerFindActive*
To control whether you are taken to the active window when selecting a buffer,
use: >
  let g:bufExplorerFindActive=0        " Do not go to active window.
  let g:bufExplorerFindActive=1        " Go to active window.
The default is to be taken to the active window.

                                                         *g:bufExplorerFuncRef*
When a buffer is selected, the functions specified either singly or as a list
will be called.

                                                     *g:bufExplorerReverseSort*
To control whether to sort the buffer in reverse order or not, use: >
  let g:bufExplorerReverseSort=0       " Do not sort in reverse order.
  let g:bufExplorerReverseSort=1       " Sort in reverse order.
The default is NOT to sort in reverse order.

                                                 *g:bufExplorerShowDirectories*
Directories usually show up in the list from using a command like ":e .".
To control whether to show directories in the buffer list or not, use: >
  let g:bufExplorerShowDirectories=0   " Do not show directories.
  let g:bufExplorerShowDirectories=1   " Show directories.
The default is to show directories.

                                                      *g:bufExplorerShowNoName*
To control whether to show "No Name" buffers or not, use: >
  let g:bufExplorerShowNoName=0        " Do not "No Name" buffers.
  let g:bufExplorerShowNoName=1        " Show "No Name" buffers.
The default is to NOT show "No Name buffers.

                                                *g:bufExplorerShowRelativePath*
To control whether to show absolute paths or relative to the current
directory, use: >
  let g:bufExplorerShowRelativePath=0  " Show absolute paths.
  let g:bufExplorerShowRelativePath=1  " Show relative paths.
The default is to show absolute paths.

                                                   *g:bufExplorerShowTabBuffer*
To control whether or not to show buffers on for the specific tab or not, use: >
  let g:bufExplorerShowTabBuffer=0        " No.
  let g:bufExplorerShowTabBuffer=1        " Yes.
The default is not to show.

                                                    *g:bufExplorerShowUnlisted*
To control whether to show unlisted buffers or not, use: >
  let g:bufExplorerShowUnlisted=0      " Do not show unlisted buffers.
  let g:bufExplorerShowUnlisted=1      " Show unlisted buffers.
The default is to NOT show unlisted buffers.

                                                          *g:bufExplorerSortBy*
To control what field the buffers are sorted by, use: >
  let g:bufExplorerSortBy='extension'  " Sort by file extension.
  let g:bufExplorerSortBy='fullpath'   " Sort by full file path name.
  let g:bufExplorerSortBy='mru'        " Sort by most recently used.
  let g:bufExplorerSortBy='name'       " Sort by the buffer's name.
  let g:bufExplorerSortBy='number'     " Sort by the buffer's number.
The default is to sort by mru.

                                                      *g:bufExplorerSplitBelow*
To control where the new split window will be placed above or below the
current window, use: >
  let g:bufExplorerSplitBelow=1        " Split new window below current.
  let g:bufExplorerSplitBelow=0        " Split new window above current.
The default is to use whatever is set by the global &splitbelow
variable.

                                                   *g:bufExplorerSplitHorzSize*
To control the size of the new horizontal split window. use: >
  let g:bufExplorerSplitHorzSize=n     " New split window is n rows high.
  let g:bufExplorerSplitHorzSize=0     " New split window size set by Vim.
The default is 0, so that the size is set by Vim.

                                                *g:bufExplorerSplitOutPathName*
To control whether to split out the path and file name or not, use: >
  let g:bufExplorerSplitOutPathName=1  " Split the path and file name.
  let g:bufExplorerSplitOutPathName=0  " Don't split the path and file
                                       " name.
The default is to split the path and file name.

                                                      *g:bufExplorerSplitRight*
To control where the new vsplit window will be placed to the left or right of
current window, use: >
  let g:bufExplorerSplitRight=0        " Split left.
  let g:bufExplorerSplitRight=1        " Split right.
The default is to use the global &splitright.

                                                   *g:bufExplorerSplitVertSize*
To control the size of the new vertical split window. use: >
  let g:bufExplorerVertSize=n          " New split window is n columns wide.
  let g:bufExplorerVertSize=0          " New split windows size set by Vim.
The default is 0, so that the size is set by Vim.

===============================================================================
CHANGE LOG                                              *bufexplorer-changelog*

7.4.12   September, 30, 2016
    - Thanks again to Martin Vuille for several more fixes related to making
      bufexplorer more tab-friendly.
7.4.11   September, 20, 2016
    - Thanks to Martin Vuille for reworking the per-tab buffer listing code.
      Fix for g:bufExplorerShowTabBuffer is not working correctly and other
      "gliches" when the ShotTabBuffer option is enabled.  For example old
      code would not correctly handle adding/deleting a tab that wasn't the
      highest-numbered tab.
7.4.10   August 26, 2016
    - Thanks to buddylindsey for fixing a misspelling in the docs.
7.4.9    April 01, 2016
    - Thanks to ivegotasthma for supplying a patch to fix a major issue with
      plugin performance when lots of buffers are open.
    - Thanks to ershov for the patch to fix grouping of files in ambiguous
      sort modes.
    - Thanks to PhilRunninger for changing documentation to use <Leader>, in
      place of '\'.
7.4.8    January 27, 2015
    - Thanks to Marius Gedminas for fixing up the documentation and correcting
      various typos.
7.4.7    January 20, 2015
    - Thanks goes out to Phil Runninger for added the ability to toggle the
      bufexplorer list on and off using the :ToggleBufExplorer command, the
      map <Leader>bt, and the function ToggleBufExplorer().
7.4.6    November 03, 2014
    - Not sure how, but the file format was converted to Dos instead of Unix.
      I converted the file back to Unix.
7.4.5    October 24, 2014
    - Dr Michael Henry suggested to change all noremap commands to nnoremap.
      Using noremap is unnecessarily broad and can cause problems, especially
      for select mode.
7.4.4    August 19, 2014
    - Revert change where bufexplorer windows was closed even if the target
      buffer has not been loaded yet.
7.4.3    August 13, 2014
    - Ivan Ukhov fixed issue with deleting the last window.  This update also
      fixes as well as another.  If you have say, NERDtree open on the left
      side and bufexplorer on the right, that bufexplorer would close NERDtree
      erroneously thinking that it is closing itself.
    - Radoslaw Burny fixed a few bugs that surfaced when bufexplorer is used
      within winmanager.
7.4.2    October 22, 2013
    - Added global option g:bufExplorerDisableDefaultKeyMapping.  This option
      controls weather the default key mappings (\be, \bs, and \bv) are
      enabled or not.  See documentation for more information.
7.4.1    October 11, 2013
    - First update related to Vim 7.4.
    - Changed license text.
    - Fixed issue with 'hidden'.  If 'hidden' is set, make sure that
      g:bufExplorerFindActive is set to 0.  Otherwise, when using \bs or \bv,
      and selecting a buffer, the original buffer will be switched to instead
      of being opened in the newly created windows.
    - Added new 'b' mapping when the bufExplorer window is opened.  When 'b'
      is pressed, the user is prompted for the buffer number to switch to, and
      is is then switched to when <CR> is pressed.  This allows for somewhat
      faster buffer switching instead of using the j and k keys or the mouse
      to select the buffer to switch to.
    - Removed 'set nolist' from the Initialize() function as well as the
      restore of the 'list' setting in the CleanUp() function.  These were
      causing issues when multiple new files were opened from the command
      line.  Furthermore, there was really no reason, that I can remember, to
      why the 'list' setting was saved, modified, and restored anyways.
    - Fixed issue with WinManager integration code not working correctly
      anymore.
    - Brought back the xnoremap setup for the 'd' and 'D' keys.  These were
      removed for some reason after version 7.2.8.
    - Thanks to all the contributors and testers.
7.3.6    May 06, 2013
    - Removed the 'drop' window command that was causing issue with the
      argument-list being modified after the BufExplorer windows was
      displayed.
7.3.5    February 08, 2013
    - Michael Henry added the ability to view "No Name" buffers.  This
      functionality was lost since version 7.3.0.  He also did some removal of
      "dead" code and cleaned up the code to handle filenames with embedded
      '"'.
7.3.4    January 28, 2013
    - Thanks go out to John Szakmeister for finding and fixing a bug in the
      RebuildBufferList method.  The keepjumps line that clears the list could
      potentially reference a backwards range.
7.3.3    January 14, 2013
    - Major cleanup and reorganization of the change log.
    - We welcome the return of g:bufExplorerSplitHorzSize and
      g:bufExplorerSplitVertSize.  When setting these values, anything less
      than or equal to 0 causes the split windows size to be determined by
      Vim.  If for example you want your new horizontal split window 10 rows
      high, set g:bufExplorerSplitHorzSize = 10 in your .vimrc.  Similar would
      be done if wanting a vertical split except you would use the
      g:bufExplorerSplitVertSize variable instead.
7.3.2    December 24, 2012
    - Thanks go out to Michael Henry for pointing out that I completely
      missed yet another function, ReverseSortSelect(), during the
      refactoring.  This function has now returned.
7.3.1    December 06, 2012
    - Thanks go out to Brett Rasmussen for pointing out that the feature
      added way back in version 7.2.3 by Yuriy Ershov to automatically
      reposition the cursor to the line containing the active buffer, was
      no longer in the plugin.  That bit of code has been re-added and
      all is well.
7.3.0    October 09, 2012
    - It has been quite a while since I published a new version and this
      is the first version since Vim 7.3 was released.  I have put some
      time into reworking and cleaning up the code as well as various bug
      fixes.  Overall, I am hopeful that I not forgotten or lost a feature.
    - Thanks to Tim Johnson for testing out this new version.
    - I have hopefully allowed for better mapping of the main public
      methods as is explained in the |bufexplorer-customization| section
      of the documentation.
    - Add new 'B', 'o', and 'S' key mappings.
7.2.8    November 08, 2010
    - Thanks to Charles Campbell for integrating bufexplorer with GDBMGR.
      http://mysite.verizon.net/astronaut/vim/index.html#GDBMGR
7.2.7    April 26, 2010
    - My 1st attempt to fix the "cache" issue where buffers information
      has changed but the cache/display does not reflect those changes.
      More work still needs to be done.
7.2.6    February 12, 2010
    - Thanks to Michael Henry for pointing out that I totally forgot to
      update the inline help to reflect the previous change to the 'd'
      and 'D' keys. Opps!
7.2.5    February 10, 2010
    - Philip Morant suggested switching the command (bwipe) associated
      with the 'd' key with the command (bdelete) associated with the 'D'
      key. This made sense since the 'd' key is more likely to be used
      compared to the 'D' key.
7.2.4    January 14, 2010
    - I did not implement the patch provided by Godefroid Chapelle
      correctly. I missed one line which happened to be the most important
      one :)
7.2.3    December 15, 2009
    - Hopefully I have not left anyone or anything out :)
    - Thanks to David Fishburn for helping me out with a much needed
      code overhaul as well as some awesome performance enhancements.
    - David also reworked the handling of tabs.
    - Thanks to Vladimir Dobriakov for making the suggestions on
      enhancing the documentation to include a better explaination of
      what is contained in the main bufexplorer window.
    - Thanks to Yuriy Ershov for added code that when the bufexplorer
      window is opened, the cursor is now positioned at the line with the
      active buffer (useful in non-MRU sort modes).
    - Yuriy also added the abiltiy to cycle through the sort fields in
      reverse order.
    - Thanks to Michael Henry for supplying a patch that allows
      bufexplorer to be opened even when there is one buffer or less.
    - Thanks to Godefroid Chapelle for supplying a patch that fixed
      MRU sort order after loading a session.
7.2.2    November 19, 2008
    - Thanks to David L. Dight for spotting and fixing an issue when using
      ctrl^. bufexplorer would incorrectly handle the previous buffer so
      that when ctrl^ was pressed the incorrect file was opened.
7.2.1    September 03, 2008
    - Thanks to Dimitar for spotting and fixing a feature that was
      inadvertently left out of the previous version. The feature was when
      bufexplorer was used together with WinManager, you could use the tab
      key to open a buffer in a split window.
7.2.0    August 15, 2008
    - For all those missing the \bs and \bv commands, these have now
      returned. Thanks to Phil O'Connell for asking for the return of
      these missing features and helping test out this version.
    - Fixed problem with the bufExplorerFindActive code not working
      correctly.
    - Fixed an incompatibility between bufexplorer and netrw that caused
      buffers to be incorrectly removed from the MRU list.
7.1.7    December 21, 2007
    - TaCahiroy fixed several issues related to opening a buffer in a tab.
7.1.6    December 01, 2007
    - Removed ff=unix from modeline in bufexplorer.txt. Found by Bill
      McCarthy.
7.1.5    November 30, 2007
    - Could not open unnamed buffers. Fixed by TaCahiroy.
7.1.4    November 16, 2007
    - Sometimes when a file's path has 'white space' in it, extra buffers
      would be created containing each piece of the path. i.e:
      opening c:\document and settings\test.txt would create a buffer
      named "and" and a buffer named "Documents". This was reported and
      fixed by TaCa Yoss.
7.1.3    November 15, 2007
    - Added code to allow only one instance of the plugin to run at a time.
      Thanks Dennis Hostetler.
7.1.2    November 07, 2007
    - Dave Larson added handling of tabs.
    - Dave Larson removed \bs and \bv commands because these are easier for
      the used to create horizontal and vertical windows.
    - Fixed a jumplist issue spotted by JiangJun. I overlooked the
      'jumplist' and with a couple calls to 'keepjumps', everything is fine
      again.
    - Went back to using just a plugin file, instead of both an autoload
      and plugin file. The splitting of the file caused issues with other
      plugins.  So if you have a prior version of bufexplorer that has an
      autoload file, please remove autoload\bufexplorer and
      plugin\bufexplorer before installing this new version.
    - Fixed E493 error spotted by Thomas Arendsen Hein.
    - Minor cosmetic changes.
    - Minor help file changes.
7.1.1    August 02, 2007
    - A problem spotted by Thomas Arendsen Hein.  When running Vim
      (7.1.94), error E493 was being thrown.
    * Added 'D' for 'delete' buffer as the 'd' command was a 'wipe' buffer.
7.1.0    August 01, 2007
    - Another 'major' update, some by Dave Larson, some by me.
    - Making use of 'autoload' now to make the plugin load quicker.
    - Removed '\bs' and '\bv'. These are now controlled by the user. The
      user can issue a ':sp' or ':vs' to create a horizontal or vertical
      split window and then issue a '\be'
    - Added handling of tabs.
7.0.17   July 24, 2007
    - Fixed issue with 'drop' command.
    - Various enhancements and improvements.
7.0.16   May 15, 2007
    - Fixed issue reported by Liu Jiaping on non Windows systems, which was
      ...
      Open file1, open file2, modify file1, open bufexplorer, you get the
      following error:

      --------8<--------
      Error detected while processing function
      <SNR>14_StartBufExplorer..<SNR>14_SplitOpen:
      line    4:
      E37: No write since last change (add ! to override)

      But the worse thing is, when I want to save the current buffer and
      type ':w', I get another error message:
      E382: Cannot write, 'buftype' option is set
      --------8<--------

7.0.15   April 27, 2007
    - Thanks to Mark Smithfield for suggesting bufexplorer needed to handle
      the ':args' command.
7.0.14   March 23, 2007
    - Thanks to Randall Hansen for removing the requirement of terminal
      versions to be recompiled with 'gui' support so the 'drop' command
      would work. The 'drop' command is really not needed in terminal
      versions.
7.0.13   February 23, 2007
    - Fixed integration with WinManager.
    - Thanks to Dave Eggum for another update.
      * Fix: The detailed help didn't display the mapping for toggling
        the split type, even though the split type is displayed.
      * Fixed incorrect description in the detailed help for toggling
        relative or full paths.
      * Deprecated s:ExtractBufferNbr(). Vim's str2nr() does the same
        thing.
      * Created a s:Set() function that sets a variable only if it hasn't
        already been defined. It's useful for initializing all those
        default settings.
      * Removed checks for repetitive command definitions. They were
        unnecessary.
      * Made the help highlighting a little more fancy.
      * Minor reverse compatibility issue: Changed ambiguous setting
        names to be more descriptive of what they do (also makes the code
        easier to follow):
            Changed bufExplorerSortDirection to bufExplorerReverseSort
            Changed bufExplorerSplitType to bufExplorerSplitVertical
            Changed bufExplorerOpenMode to bufExplorerUseCurrentWindow
      * When the BufExplorer window closes, all the file-local marks are
        now deleted. This may have the benefit of cleaning up some of the
        jumplist.
      * Changed the name of the parameter for StartBufExplorer from
        "split" to "open". The parameter is a string which specifies how
        the buffer will be open, not if it is split or not.
      * Deprecated DoAnyMoreBuffersExist() - it is a one line function
        only used in one spot.
      * Created four functions (SplitOpen(), RebuildBufferList(),
        UpdateHelpStatus() and ReSortListing()) all with one purpose - to
        reduce repeated code.
      * Changed the name of AddHeader() to CreateHelp() to be more
        descriptive of what it does. It now returns an array instead of
        updating the window directly. This has the benefit of making the
        code more efficient since the text the function returns is used a
        little differently in the two places the function is called.
      * Other minor simplifications.
7.0.12   November 30, 2006
    - MAJOR Update.  This version will ONLY run with Vim version 7.0 or
      greater.
    - Dave Eggum has made some 'significant' updates to this latest
      version:
      * Added BufExplorerGetAltBuf() global function to be used in the
        user's rulerformat.
      * Added g:bufExplorerSplitRight option.
      * Added g:bufExplorerShowRelativePath option with mapping.
      * Added current line highlighting.
      * The split type can now be changed whether bufexplorer is opened
        in split mode or not.
      * Various major and minor bug fixes and speed improvements.
      * Sort by extension.
    - Other improvements/changes:
      * Changed the help key from '?' to <F1> to be more 'standard'.
      * Fixed splitting of vertical bufexplorer window.
    - Hopefully I have not forgot something :)
7.0.11   March 10, 2006
    - Fixed a couple of highlighting bugs, reported by David Eggum.
    - Dave Eggum also changed passive voice to active on a couple of
      warning messages.
7.0.10   March 02, 2006
    - Fixed bug report by Xiangjiang Ma. If the 'ssl' option is set,
      the slash character used when displaying the path was incorrect.
7.0.9    February 28, 2006
    - Martin Grenfell found and eliminated an annoying bug in the
      bufexplorer/winmanager integration. The bug was were an
      annoying message would be displayed when a window was split or
      a new file was opened in a new window. Thanks Martin!
7.0.8    January 18, 2006
    - Thanks to Mike Li for catching a bug in the WinManager integration.
      The bug was related to the incorrect displaying of the buffer
      explorer's window title.
7.0.7    December 19, 2005
    - Thanks to Jeremy Cowgar for adding a new enhancement. This
      enhancement allows the user to press 'S', that is capital S, which
      will open the buffer under the cursor in a newly created split
      window.
7.0.6    November 18, 2005
    - Thanks to Larry Zhang for finding a bug in the "split" buffer code.
      If you force set g:bufExplorerSplitType='v' in your vimrc, and if you
      tried to do a \bs to split the bufexplorer window, it would always
      split horizontal, not vertical.
    - Larry Zhang also found that I had a typeo in that the variable
      g:bufExplorerSplitVertSize was all lower case in the documentation
      which was incorrect.
7.0.5    October 18, 2005
    - Thanks to Mun Johl for pointing out a bug that if a buffer was
      modified, the '+' was not showing up correctly.
7.0.4    October 03, 2005
    - Fixed a problem discovered first by Xiangjiang Ma. Well since I've
      been using vim 7.0 and not 6.3, I started using a function (getftype)
      that is not in 6.3. So for backward compatibility, I conditionaly use
      this function now.  Thus, the g:bufExplorerShowDirectories feature is
      only available when using vim 7.0 and above.
7.0.3    September 30, 2005
    - Thanks to Erwin Waterlander for finding a problem when the last
      buffer was deleted. This issue got me to rewrite the buffer display
      logic (which I've wanted to do for sometime now).
    - Also great thanks to Dave Eggum for coming up with idea for
      g:bufExplorerShowDirectories. Read the above information about this
      feature.
7.0.2    March 25, 2005
    - Thanks to Thomas Arendsen Hein for finding a problem when a user
      has the default help turned off and then brought up the explorer. An
      E493 would be displayed.
7.0.1    March 10, 2005
    - Thanks to Erwin Waterlander for finding a couple problems.
      The first problem allowed a modified buffer to be deleted.  Opps! The
      second problem occurred when several files were opened, BufExplorer
      was started, the current buffer was deleted using the 'd' option, and
      then BufExplorer was exited. The deleted buffer was still visible
      while it is not in the buffers list. Opps again!
7.0.0    March 10, 205
    - Thanks to Shankar R. for suggesting to add the ability to set
      the fixed width (g:bufExplorerSplitVertSize) of a new window
      when opening bufexplorer vertically and fixed height
      (g:bufExplorerSplitHorzSize) of a new window when opening
      bufexplorer horizontally. By default, the windows are normally
      split to use half the existing width or height.
6.3.0    July 23, 2004
    - Added keepjumps so that the jumps list would not get cluttered with
      bufexplorer related stuff.
6.2.3    April 15, 2004
    - Thanks to Jay Logan for finding a bug in the vertical split position
      of the code. When selecting that the window was to be split
      vertically by doing a '\bv', from then on, all splits, i.e. '\bs',
      were split vertically, even though g:bufExplorerSplitType was not set
      to 'v'.
6.2.2    January 09, 2004
    - Thanks to Patrik Modesto for adding a small improvement. For some
      reason his bufexplorer window was always showing up folded. He added
      'setlocal nofoldenable' and it was fixed.
6.2.1    October 09, 2003
    - Thanks goes out to Takashi Matsuo for added the 'fullPath' sorting
      logic and option.
6.2.0    June 13, 2003
    - Thanks goes out to Simon Johann-Ganter for spotting and fixing a
      problem in that the last search pattern is overridden by the search
      pattern for blank lines.
6.1.6    May 05, 2003
    - Thanks to Artem Chuprina for finding a pesky bug that has been around
      for sometime now. The <esc> key mapping was causing the buffer
      explored to close prematurely when vim was run in an xterm. The <esc>
      key mapping is now removed.
6.1.5    April 28, 2003
    - Thanks to Khorev Sergey. Added option to show default help or not.
6.1.4    March 18, 2003
    - Thanks goes out to Valery Kondakoff for suggesting the addition of
      setlocal nonumber and foldcolumn=0. This allows for line numbering
      and folding to be turned off temporarily while in the explorer.
6.1.3    March 11, 2003
    - Added folding.
    - Did some code cleanup.
    - Added the ability to force the newly split window to be temporarily
      vertical, which was suggested by Thomas Glanzmann.
6.1.2    November 05, 2002
    - Now pressing the <esc> key will quit, just like 'q'.
    - Added folds to hide winmanager configuration.
    - If anyone had the 'C' option in their cpoptions they would receive
      a E10 error on startup of BufExplorer. cpo is now saved, updated and
      restored. Thanks to Charles E Campbell, Jr.
    - Attempted to make sure there can only be one BufExplorer window open
      at a time.
6.1.1    March 28, 2002
    - Thanks to Brian D. Goodwin for adding toupper to FileNameCmp. This
      way buffers sorted by name will be in the correct order regardless of
      case.
6.0.16   March 14, 2002
    - Thanks to Andre Pang for the original patch/idea to get bufexplorer
      to work in insertmode/modeless mode (evim).
    - Added Initialize and Cleanup autocommands to handle commands that
      need to be performed when starting or leaving bufexplorer.
6.0.15   February 20, 2002
    - Srinath Avadhanulax added a patch for winmanager.vim.
6.0.14   February 19, 2002
    - Fix a few more bug that I thought I already had fixed.
    - Thanks to Eric Bloodworth for adding 'Open Mode/Edit in Place'.
    - Added vertical splitting.
6.0.13   February 05, 2002
    - Thanks to Charles E Campbell, Jr. for pointing out some embarrassing
      typos that I had in the documentation. I guess I need to run the
      spell checker more :o)
6.0.12   February 04, 2002
    - Thanks to Madoka Machitani, for the tip on adding the augroup command
      around the MRUList autocommands.
6.0.11   January 26, 2002
    - Fixed bug report by Xiangjiang Ma. '"=' was being added to the search
      history which messed up hlsearch.
6.0.10   January 14, 2002
    - Added the necessary hooks so that the Srinath Avadhanula's
      winmanager.vim script could more easily integrate with this script.
    - Tried to improve performance.
6.0.9    December 17, 2001
    - Added MRU (Most Recently Used) sort ordering.
6.0.8    December 03, 2001
    - Was not resetting the showcmd command correctly.
    - Added nifty help file.
6.0.7    November 19, 2001
    - Thanks to Brett Carlane for some great enhancements. Some are added,
      some are not, yet. Added highlighting of current and alternate
      filenames. Added splitting of path/filename toggle. Reworked
      ShowBuffers().
    - Changed my email address.
6.0.6    September 05, 2001
    - Copyright notice added. Needed this so that it could be distributed
      with Debian Linux.
    - Fixed problem with the SortListing() function failing when there was
      only one buffer to display.
6.0.5    August 10, 2001
    - Fixed problems reported by David Pascoe, in that you where unable to
      hit 'd' on a buffer that belonged to a files that no longer existed
      and that the 'yank' buffer was being overridden by the help text when
      the bufexplorer was opened.
6.0.4    July, 31, 2001
    - Thanks to Charles Campbell, Jr. for making this plugin more plugin
      *compliant*, adding default keymappings of <Leader>be and <Leader>bs
      as well as fixing the 'w:sortDirLabel not being defined' bug.
6.0.3    July 30, 2001
    - Added sorting capabilities. Sort taken from explorer.vim.
6.0.2    July 25, 2001
    - Can't remember.
6.0.1    Sometime before July 25, 2001
    - Initial release.

===============================================================================
TODO                                                         *bufexplorer-todo*

- Add ability to open a buffer in a horizontal or vertical split after the
  initial bufexplorer window is opened.

===============================================================================
CREDITS                                                   *bufexplorer-credits*

Author: Jeff Lanzarotta <delux256-vim at yahoo dot com>

Credit must go out to Bram Moolenaar and all the Vim developers for
making the world's best editor (IMHO). I also want to thank everyone who
helped and gave me suggestions. I wouldn't want to leave anyone out so I
won't list names.

===============================================================================
COPYRIGHT                                               *bufexplorer-copyright*

Copyright (c) 2001-2016, Jeff Lanzarotta
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its contributors may
  be used to endorse or promote products derived from this software without
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

===============================================================================
vim:tw=78:noet:wrap:ts=4:ft=help:norl:
