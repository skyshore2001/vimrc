" Author : Liang, Jian <liangjian_2001@126.com>
" 	Customize vim environment for easy using

"================== basic environment{{{
set tabstop=4
set shiftwidth=4
set autoindent

set encoding=utf-8
"set langmenu=zh_CN.UTF-8
" language message zh_CN.UTF-8
set langmenu=en_US.UTF-8
language message en_US.UTF-8
set fileencodings=ucs-bom,utf-8,cp936,utf-16le

set nowrap

" for vim under win32 command (my command window using white background)
" ! has("gui_running")
if &term == "win32" 
	colorscheme peachpuff
endif

set display+=lastline
" uhex

" ȱʡ���������@z��
" ��ʼ: redir @z
" to retrive: ctrl-r ctrl-o z 
" ����: redir end 

set nocompatible
source $VIMRUNTIME/vimrc_example.vim
source $VIMRUNTIME/mswin.vim
behave mswin
" �ָ������������(����mswinӳ���redo)
unmap <C-Y>

" �ָ�ctrl-A ��ԭʼ���ܣ���ctrl-x��ӦΪ���ӻ������ֵ
" unmap <C-A>
" ������ĸ++��--
set nrformats=alpha

" don't use swapfile (equal to: vi -n <file>)
" set updatecount=0
" use the same swap dir
silent! call mkdir('c:/tmp')
set dir=c:\tmp

" ���Ҫ�򿪴��ļ���
" 1. syntax off
" 2. set noswapfile "��ѡ��ֻ�����ڵ�ǰbuffer
" 3. set mm=2000000 mmt=2000000
" Ȼ���ټ���
" ���õ���buf��maxmemΪ���(2G)���Ա�򿪴����ı��ļ�
" �������swapfile��ﵽ����ڴ�󱨴�˵�ڴ治��
" set mm=2000000 mmt=2000000

" �鿴��༭�������ļ�
"nmap \bin :lang C \| set encoding=latin1 display+=uhex \| n ++bin ++enc=latin1 %<cr>
nmap \bin :set binary noeol display+=uhex<cr>

" close other windows (ignore changes): <C-W>O
nmap <C-W>O :only!<CR>
	
" quit without save; !!! override the default <C-W>q to :q!
nmap <C-W>q :q!<CR>

" set ignorecase as default, will affect search && auto complete && tag jump...
set ignorecase
set smartcase
" switch option ignorecase
nmap \ic :set ignorecase!<cr>:set ignorecase?<cr>

" simulate <enter> in normal mode: by ctrl-enter
nmap <C-CR> i<CR><ESC>

" search after select in visual mode: by <Enter> key (<cword>��ʾ��괦�Ĵʣ�������)
"vmap <Enter> y:let @/=getreg('0')<CR>
vmap <Enter> y:let @/=@0<CR>

" move cursor in insert mode without leaving main keyboard
if &term != "win32"
	imap <C-H> <Left>
	imap <C-L> <Right>
	" imap <C-J> <Down>
	" imap <C-K> <Up>
	imap <C-J> <c-o>gj
	imap <C-K> <c-o>gk
endif	
imap <C-D> <Delete>

" simple alias to move between windows
nmap <C-J> <C-W>j
nmap <C-K> <C-W>k
nmap <C-H> <C-W>h
nmap <C-L> <C-W>l

" alt-j/k: move based on screen line
nmap <m-j> gj
nmap <m-k> gk

" reload/refresh currect file
" Shift-F5 Ĭ�ϱ������¼���
nmap <S-F5> :n! %<cr>
" F5:ѡ��unicode�������¼���
nmap <F5> :call LoadFileEnc('')<cr>
" C-S-F5:�״�ʹ�ÿ�ѡ�����; �ٴ�ʹ��ʱ���ϴ�ѡ���unicode����
nmap <C-S-F5> :call LoadFileEnc('auto')<cr>

" argΪ''ʱ����ѡ�����
fu! LoadFileEnc (arg)
	if a:arg == '' || !exists('g:last_enc')
		let enc_ls = ['utf8', 'ucs-2le', 'ucs-2be', 'cp936']
		let choice = inputlist(['choose encoding:', '1. utf8', '2. ucs-2le (unicode little endian)', '3. ucs-2be (unicode big endian - utf16)', '4. cp936'])
		if choice == 0 || choice > len(enc_ls)+1
			return
		endif
		let g:last_enc = enc_ls[choice-1]
	endif
	exe 'set encoding=' . g:last_enc
	language message zh_CN.UTF-8
	exe 'n! ++enc=' . g:last_enc . ' %'
	let g:last_enc = &fileencoding
endf

" for viewing and editing unicode files
nmap \uni :set encoding=utf-8<CR>:language message zh_CN.UTF-8<CR>:n! %<CR>
" set encoding=utf-8
" set langmenu=zh_CN.UTF-8
" language message zh_CN.UTF-8

" save file
map <C-S> :up!<CR>

" set nowrap and wrap
nmap <F11> :set nowrap<CR>
nmap <S-F11> :set wrap<CR>

" save and load session
nmap \sav :mksession!<CR>
nmap \lod :so Session.vim<CR>

" ֧����ת���ļ��к� (��aa.txt:100 ��gF, ^W-F����ת���к�)
" set isfname-=:
" ����������ã��� c:\aa.txt �������ļ��޷���ת

" Rename: e.g. Ren aaa.txt
command! -nargs=1 -complete=file Ren if rename(expand("%"), "<args>")==0 | n <args> | else | echo "FAIL" | endif

" insertģʽ��<F5>��������(��notepad��һ��)
"imap <F5> <esc>:call append(".", [strftime("%Y/%m/%d %X")])<cr>JA
imap <F5> <C-R>=strftime("%Y/%m/%d %X")<cr>

" ---- autocmd
" use cindent
au FileType c,cpp,perl set cindent
" use :au to see all the file type setting

" set indent and shiftwidth for html-like files
" au FileType *.htm,*.html,*.jsp,*.asp set ts=2
au FileType html,xml,xslt setl ts=2 sw=2
" au FileType jsp,php,asp set ts=2 sw=2

autocmd BufNewFile,BufRead *.json set ft=javascript

" ---- set tab and shift width
function SetTs(ts)
	let cmd = "set tabstop=" . a:ts . " | set shiftwidth=" . a:ts 
	exe cmd
endf
nmap \tab :call SetTs(input("tabstop: ", 2))<CR>

" ------ vimrc
" edit vimrc
nmap \rc :e $VIM/_vimrc<CR>
" apply vimrc
nmap \RC :silent! source $VIM/_vimrc<CR>

" ------ set syntax
" syntax to ... (customised)
function SetSyn(syn)
	" ����һ
" 	exe ':syntax clear'
" 	exe ':ru! syntax/' . a:syn . '.vim'

	" ������
	exe "set syntax=". a:syn

 	echo 'Load "' . a:syn . '.vim".'
endf
function SelectSyn()
	let syn = input('Sync: ', 'cpp')
	call SetSyn(syn)
endfunction

nmap \syn :call SelectSyn()<CR>
" nmap \syn :syn clear<CR>:ru! syntax/cpp.vim

" customize syntax "keyword" element
nmap \ksyn :syn keyword Type 
" customize syntax "match" element 
nmap \msyn :syn match Title /p/

" ---- from vim62 to vim63:
set hlsearch
set backspace=indent,eol,start
syntax on

set nobackup
set nowritebackup

" don't use visual beep in gui
set novb

" don't show gui toolbar
set guioptions-=T
set guioptions+=bh " bottom horizontal scrollbar
" set guioptions-=m  " menu
" let did_install_syntax_menu = 0

" always show status bar
set laststatus=2
" status bar format
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P

" ========= for vim7.0 diff
set diffexpr=MyDiff()
function MyDiff()
  let opt = '-a --binary '
  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
  let arg1 = v:fname_in
  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
  let arg2 = v:fname_new
  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
  let arg3 = v:fname_out
  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
  let eq = ''
  if $VIMRUNTIME =~ ' '
    if &sh =~ '\<cmd'
      let cmd = '""' . $VIMRUNTIME . '\diff"'
      let eq = '"'
    else
      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
    endif
  else
    let cmd = $VIMRUNTIME . '\diff'
  endif
  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction

" ========= for vim7.0 �ؼ��ֲ�ȫ (Ĭ��completeopt=menu,preview)
" ��ɨ��include�ļ��Խ�Լʱ��
set complete-=i
" ��ɨ��tag. tag��<C-]>����<C-N>���
set complete-=t
" set completeopt=
" ��tag��ȫ
inoremap <C-]>             <C-X><C-]>
" ��ȫ�ļ���
inoremap <C-F>             <C-X><C-F>

" eval this line
nmap \E o<c-r>=string(eval(getline(line('.')-1)))<cr><esc>0
vmap \E yo<c-r>=string(<c-r>0)<cr><esc>0
"}}}

"================== for developers{{{
" -------- run program <F9> {{{
" set a program and run in shell: s<F9>
nmap <silent> s<F9> :if SetRunProg() \| call RunProg(0) \| endif<CR>

" run program in shell
nmap <silent> <F9> :call RunProg(0)<CR>

" view terminal screen
" in windows OS
nmap <silent> <F12> :!start cmd<CR>
nmap <silent> \exp :!start explorer %:p:h<CR>
" in linux
" nmap <F12> :!<CR> 

" run program and echo the result in VI : \r (cannot be a interactive program!)
" nmap \r :call RunProg(1)<CR>
" show again the result : \v
" nmap \v :echo getreg('z')<CR>

" run shell command : <F2>
" run an external command and direct result to a new window (^W-q to quit the window)
nmap <silent> <F2> :call RunCmd(0)<CR>

" return: T/F
function! SetRunProg()
	if !exists("g:run_prog")
		let g:run_prog = '%'
	endif
	let cmd = input("Run program: ", g:run_prog)
	if cmd != '' 
		let g:run_prog = cmd
		return 1
	endif
endf

" run specified program (default program is specified in l:var 'g:myprog'), support special variable '%' and '%:r'
" using var: g:run_prog
function! RunProg(b_direct_show)
	if expand('%:e') == "vim"
		so %
		return
	endif

	if !exists("g:run_prog")
		call SetRunProg()
	endif

	" support '%' and '%:r' : e.g. '%.r' -> 'aaa.c' -> 'aaa':
	try
		if a:b_direct_show
			" redirect to register 'z'. to view: \v or :echo getreg("z")
			call setreg('z', system(g:run_prog))
			echo getreg('z')
		else
			if g:run_prog =~ '\.vim$\c'
				exe 'so ' . g:run_prog
			else
				exe ':! ' . g:run_prog
			endif
		endif
	catch /.*/
		echo 'Caught "' . v:exception . '" in ' . v:throwpoint
	finally
	endtry
endfunction

function! CloseWindow()
	let choice=confirm("Close this window?", "&Yes\n&No\n", 1)
	if choice == 1
		normal ZQ
	endif
endfunction

" using gvar: 'g:run_cmd'
function! RunCmd(b_direct_show)
	if !exists("g:run_cmd")
		let g:run_cmd = '%'
	endif
	let g:run_cmd = input("Run command: ", g:run_cmd)

	try
		if (a:b_direct_show) 
			" redirect to register 'z'. to view: \v or :echo getreg("z")
			call setreg('z', system(g:run_cmd))
			echo getreg('z')
		else
			" support '%' and '%:r' (expand)
			let cmdstr = g:run_cmd
			let cmdstr = substitute (cmdstr, '%:r', substitute(expand('%:r'), '\\', '/', 'g'), 'g')
			let cmdstr = substitute (cmdstr, '%', substitute(expand('%'), '\\', '/', 'g'), 'g')       " e.g.  '%' -> filename
			" open a new window and write to this window
			new
			exe ":r! " . cmdstr
		endif
	catch /.*/
		echo 'Caught "' . v:exception . '" in ' . v:throwpoint . ', g:run_cmd=' . g:run_cmd
		call CloseWindow()	
	finally
	endtry
endfunction

" }}}
" -------- make program: <F9> {{{
" save and make: <Ctrl-F9>
nmap <C-F9> :update \| make<CR>

" save and make itself: r<F9>
nmap r<F9> :update \| make %:r<CR>

" rebuild: ctrl-shift-<F9>
"nmap <C-S-F9> :update \| make clean<CR> \| make

" compile current file: Alt-<F9> 
nmap <M-F9> :update \| make %:r.o<cr>

" pre-compile: \cpp
nmap \cpp :let f=expand('%') \| new \| exe ":r! cpp " . f<cr>
" �൱�ڰ�<F2>������ cpp %
"}}}
" --------- auto comment \\ {{{
" using g:comment_str

function! SetCommentStr()
	let ext = tolower(expand("%:e"))
" 	if ext == 'pl' || ext == 'pm' || ext == 'cfg' || ext == 'txt'
" 		let g:comment_str = '#'
	if ext == 'c' || ext == 'cpp' || ext == 'h' || ext == 'cc' || ext == 'c++'
		let g:comment_str = '//'
	elseif ext == 'vbs' || ext == 'bas'
		let g:comment_str = "'"
	elseif ext == 'sql'
		let g:comment_str = "--"
	elseif ext == 'vim' || expand('%:t') =~ 'vimrc'
		let g:comment_str = '"'
	else " default
		let g:comment_str = '#'
	endif

	let g:comment_str = substitute (input('Comment str: ', g:comment_str), '/', '\\/', 'g')
endfunction

function! Comment(s_add_remove) range
	if !exists("g:comment_str")
		call SetCommentStr()
	endif
	if a:s_add_remove == "add"
		let cmd = a:firstline . ',' . a:lastline . 's/^/' . g:comment_str . ' /'
	elseif a:s_add_remove == "remove"
		let cmd = a:firstline . ',' . a:lastline . 's/^[ ]*' . g:comment_str . '[ ]\?//'
	endif
	set nohlsearch
	try 
		silent exe cmd
	catch /.*/
	finally
		nohlsearch
		set hlsearch
	endtry
endfunction

" comment or uncomment : \//
nmap \// :call Comment('add') \| echo 'ok'<CR>
nmap \/d :call Comment('remove') \| echo 'ok'<CR>

vmap \// :call Comment('add') \| echo 'ok'<CR>
vmap \/d :call Comment('remove') \| echo 'ok'<CR>

" set comment string : s//
nmap s// :call SetCommentStr() \| echo 'ok'<CR>
"}}}

" ---------- .h .c/.cpp �л�"{{{
function Switch_c_h(b_newwin)
	let cmd = (a:b_newwin || &modified ? 'new ': 'n ')
	if expand("%:e") == "h"
		for e in [".c", ".cpp", ".cc", ".C"]
			let fname = expand("%:r") . e
			if filereadable(fname)
				exe cmd . fname
				break
			endif
		endfor
	else
		let fname = expand("%:r") . '.h'
		if filereadable(fname)
			exe cmd . fname
		endif
	endif
endfunction

nmap <silent> \gg :call Switch_c_h(0)<CR>
nmap <silent> \G :call Switch_c_h(1)<CR>
"}}}

" ------------tags {{{
" make tag; require: ctags
nmap \tag :!ctags *<CR>
" make perl tag; require: pltags
nmap \ptag :!pltags.pl %<CR>

" visualģʽ��ѡ��һ������Ϊtag
vmap <c-w>] y:exe "stag " . @0<CR>
" vmap <c-]> y:exe "tag " . @0<CR> 
" c-]�Ѿ�֧��visual��

"}}}

"---------- indent or tidy{{{
" indent a C program: indent
nmap \ind :%!indent -br -ts4 -i4 -npsl -bad  -l120<CR> " indent c programs
" indent a xml or html file: xml_tidy
nmap \xml :%!xml_tidy --tidy-mark no --tab-size 2 -big5 -iq -xml -wrap 256<CR>
nmap \htm :%!xml_tidy --tidy-mark no --tab-size 2 -big5 -iq  -ashtml -wrap 256 --break-before-br yes --wrap-asp no --indent yes<CR>
" optional : --indent yes


" cindent option: (remove action: when type #, it indents to the line head) (help cin , help cink)
set cink-=0#

"=========== tity code
" for java code:
" astyle -j -b -p 
" remove space:
" :g/^\s*$/d

"}}}

" ----------- for cscope {{{
set cscopequickfix=g-,s-,t-,e-,i-,d-,c-
" f-

" �����ļ��б�cscope.files:  dir /s /b *.h *.c *.cpp > cscope.files
" ����������·��, ��cscope.files��ǰ��̶�����ɾ����
"
" �������ſ�(ʹ��cscope.files�е��ļ�, ����Ӧ����-R����): cscope -bkq
"
" refer to: http://blog.csdn.net/easwy/archive/2007/04/03/1550585.aspx
" download (windows version): http://iamphet.nm.ru/cscope/

" ���ط��ſ�: ָ����ǰ�����ļ�(-f cscope.out)��������Ŀ¼(-P ...), �����Դ�Сд(-C)
" ���[pre-dir]���пո񣬻����鷳������"O Gen", Ӧ��д��dos8.3�ļ���ʽ��Ϊ"OGen~1"
nmap \csa :cs add cscope.out <c-r>=getcwd()<cr> -C<cr>
" �رշ��ſ�
nmap \csk :cs kill -1<CR>

" " ���ҷ��Ŷ���
" nmap <c-[> :cs find g (?i)<c-r>=expand("<cword>")<cr>$<cr>
" nmap <c-w>[ :scs find g (?i)<c-r>=expand("<cword>")<cr>$<cr>
" vmap <c-[> y:cs find g (?i)<c-r>0$<cr>
" vmap <c-w>[ y:scs find g (?i)<c-r>0$<cr>

" ģ�������ļ�
nmap \csF :cs f f .*<c-r>=expand("<cword>")<cr>.*<cr>
nmap \csf :cs f f 

" ���ҷ���(���Դ�Сд)
nmap \cs<space> :cs f g <c-r>=expand("<cword>")<cr><cr>
nmap \csg :cs f g .*.*<left><left>

" ���ҵ��õ�
nmap \cs1 :cs find c <c-r>=expand("<cword>")<cr><cr>:cw<cr>
nmap \cs! :scs find c <c-r>=expand("<cword>")<cr><cr>:cw<cr>
vmap \cs1 y:cs find c <c-r>0<cr>:cw<cr>
vmap \cs! y:scs find c <c-r>0<cr>:cw<cr>
" ���ҷ�������
nmap \cs2 :cs find s <c-r>=expand("<cword>")<cr><cr>:cw<cr>
nmap \cs@ :scs find s <c-r>=expand("<cword>")<cr><cr>:cw<cr>
vmap \cs2 y:cs find s <c-r>0<cr>:cw<cr>
vmap \cs@ y:scs find s <c-r>0<cr>:cw<cr>
nmap \css :cs f s .*.*<left><left>
" egrep
nmap \cs3 :cs find e <c-r>=expand("<cword>")<cr><cr>:cw<cr>
nmap \cs# :scs find e <c-r>=expand("<cword>")<cr><cr>:cw<cr>
vmap \cs3 y:cs find e <c-r>0<cr>:cw<cr>
vmap \cs# y:scs find e <c-r>0<cr>:cw<cr>
nmap \cse :cs f e .*.*<left><left>
"}}}

" --------- project plugin: <Ctrl-F10>"{{{
" toggle project window
nmap <silent> <C-F10> <Plug>ToggleProject<CR>
" open a file match *vimprojects
au VimEnter *vimprojects Project %
" unload current project and load the default project
" nmap <silent> \P <c-w><left>:bwipe \| Project<CR>
"}}}

" --------- taglist plugin: <Ctrl-F11>"{{{
nmap <silent> <C-F11> :TlistToggle<CR>
"}}}

" ------ format sql statement{{{
" ����MSSQL2005 profiler�п�������������ʽ��
vmap \sql :call FormatSql()<cr>

" ����ԭʼ�����£�ѡ�к� \sql ������������
" exec sp_executesql N'SELECT T0.[WstCode], AVG(T1.[MaxReqr]), AVG(T0.[SortId]), T2.[Status], COUNT(T2.[Status]) FROM  [dbo].[WTM2] T0  INNER  JOIN [dbo].[OWST] T1  ON  T1.[WstCode] = T0.[WstCode]    LEFT OUTER  
" JOIN [dbo].[WDD1] T2  ON  T2.[StepCode] = T0.[WstCode]  AND  T2.[WddCode] = 15   INNER  JOIN [dbo].[WST1] T3  ON  T3.[WstCode] = T1.[WstCode]  AND  T3.[UserID] = T2.[UserID]   WHERE T0.[WtmCode] = (@P1)   GROUP 
" BY T0.[WstCode], T2.[Status] ORDER BY AVG(T0.[SortId]),T2.[Status] DESC',N'@P1 int',4

function! FormatSql() range
 	" first merge into 1 line than do replcing:
	" Ϊ��ֹvisual area��ȡ��, ����ǰ����gv��ѡ
	normal gvJ
	s/\v\c<(INSERT|UPDATE|SELECT|FROM|INNER|LEFT|RIGHT|WHERE|GROUP|ORDER|VALUES|SET|FOR)>/\r\1/g

	call SetSyn('sql')
	set nowrap

	if getline("'<") =~ '\Cexec'
		" comment the non-sql code
		exe "normal 0f'i\<cr>-- "
		'<
		normal I-- 
		normal j
	endif
endf
"}}}

"}}}

"================== others {{{
" ------- syntax fold{{{
" auto region fold (use "zE" to eliminate all the fold)

" create region fold for C/C++
nmap \zf :call RegionFold()<CR>

" restore the "manual" fold method
nmap \ze :set foldmethod=manual<CR>

" use zE to eliminate all the folds
" to use perl syntax-fold: 1) modify perl.vim, enable "perl-fold" 2) set foldmethod=syntax

function RegionFold()
	let start_regex = input("start regex: ", "^{")
	let end_regex   = input("end regex: ", "^}")
	let cmd = ':syn region myFold keepend start=/' . start_regex . '/ end=/' . end_regex . '/ transparent fold'
	exe cmd
	set foldmethod=syntax " implement the fold region
	set foldcolumn=2 
	echo "input \\ze to restore manual foldmethod."
endf
"}}}
" --------- for gdbvim"{{{
if has("gdb")
	run macros/gdb_mappings.vim
	syntax enable
	set asm=0
	set gdbprg=/usr/bin/gdb
endif
"}}}
" --------- draw <F7>{{{
map <F7> :call ToggleSketch()<CR>
" 1. rantangle
" 1) draw a simple rect, save it to register (e.g. A)
"         ,-.
"         | |
"         `-'
" 2) to extend cols: <C-V> select col and paste
" 3) to extend lines: copy lines and paste
" 4) <C-V> to select the rect and paste to your position
" 5) to add text: use replace mode (R)
"
" 2. draw table
" +-------+
" |       |
" +-------+
" |       |
" |       |
" +-------+
"
" 3. arraw:
" 1) , -->      ^
" 2) |          |
"    |          |
"    v     <----'   
"
" 4. underline
"    ^^^^^^^^^

"}}}
" --------- google search {{{
nmap \K :silent ! start http://www.google.com/search?q=<cword><cr>
" ע�� ! �����пո�
" Ӧ����url����
vmap \K y:silent ! start http://www.google.com/search?q=<c-r>=substitute(@0, ' ', '+', 'g')<cr><cr>
"}}}
" ------- spell checking : English words {{{
" Spell Checking Create (use '\scC' rather than '\scc', because capital letter is safer
nmap \scC :!perl -e 'print "\" ==== Add user defined syn here: \nsyntax keyword Tag LiangJian Liang\n\n\" ====\n"; map { chomp; print "syntax keyword Tag \\\L$_\E \\\U$_\E \\\u$_\n"; } (<>);' /usr/share/dict/words > /tmp/words.vim <CR>
" Spell Checking Load
nmap \scl :syn clear<CR>:set dict=/usr/share/dict/words<CR>:so /tmp/words.vim<CR>
" Spell Checking word Addition (add user defined words):
nmap \sca :new /tmp/words.vim<CR>
" auto complete with dict
nmap \ac :set dict=/usr/share/dict/words<CR>
"}}}
" --------- shell {{{
" ע�⣺!start �� ! start��ͬ�����߲��ܺ�����ʲô���Ҫ��һ��cmd����;
" ��ǰ���и�ȱ���ǲ��ܴ��ĵ���url����start 1.txt������(��cmd������ȴ����)������ʹ��_start.exe����
" require: d:\bat\_start.exe

" start program or doc (for windows)
nmap \st :silent !start _start <cfile><cr>
vmap \st y:silent !start _start <c-r>0<cr>
nmap \S :silent !start _start %<cr>

" google search
nmap \K :silent !start _start http://www.google.com/search?q=<cword><cr>
" nmap \K :silent ! start http://www.google.com/search?q=<cword><cr>
" ע�� ! �����пո�
" Ӧ����url����
vmap \K y:silent !start _start http://www.google.com/search?q=<c-r>=substitute(@0, ' ', '+', 'g')<cr><cr>

" open firefox
" require: d:\bat\ff.lnk and .lnk is in PATHEXT
nmap \ff :silent !start _start ff<cr>

"}}}
"}}}

" ================== customize {{{
" ------ old, not used{{{
" ------- use perl to deal with data
nmap \! :%! perl -ne "// and print"
vmap \! :! perl -ne "// and print"

" --------- auto complete 
nmap \\test ofprintf(stderr, "#### ATTTEST-L%d: %s ####\n", __LINE__, "HERE"); //????atttest<ESC>F,
nmap \\rtest oRTEST_BEGIN<CR><TAB>"rtest_name",<CR>new CmpItem<T>("item_name", out, expect);<CR>new CmpItem<T>("item_name", out, expect)<CR><LEFT>RTEST_END<UP><UP><UP><ESC>
syn keyword Title RTEST_INIT RTEST_BEGIN RTEST_END RTEST_TERM
"}}}

" ------ including path and adding tags {{{
"let $VC6='C:/Program\ Files/Microsoft\ Visual\ Studio/VC98'
"set path+=$VC6\INCLUDE,$VC6\ATL\INCLUDE,$VC6\MFC\INCLUDE
let $VC8='d:/Program\ Files/Microsoft\ Visual\ Studio\ 8/VC'
set path+=$VC8/include/**,$VC8/PlatformSDK/Include/**,$VC8/atlmfc/include/**
let $GCC='d:/mingw/include'
set path+=$GCC/**
" set path+=D:\vc7\include
" set path+=d:\dev-cpp\include,d:\dev-cpp\include\c++\3.4.2
" set path+=d:\software\ace_wrappers
" set path+=$ACE_ROOT
" set path+=d:\dev-cpp\include,d:\dev-cpp\include\g++-3
" set path+=/usr/include/c++/3.2.3
" set path+=/opt/hp93000/soc/com/include,/opt/hp93000/soc/prod_com/include,/opt/hp93000/soc/pws/include,/opt/hp93000/soc/mix_sgnl/include,/opt/hp93000/soc/pws/lib,/opt/hp93000/soc/prod_com/include/MAPI,/opt/hp93000/soc/formatter/include,/opt/hp93000/soc/fw/include,/opt/hp93000/soc/fw/hpl/include

" set tag+=/home/tags/tags
set tag+=d:/bat/tags
" e.g. refer to d:\bat\make_tags.bat
" ctags --c-types=+p -o d:\bat\tags ^
" 	D:\Dev-Cpp\include\*.h ^
" 	D:\Dev-Cpp\include\sys\*.h ^
" 	D:\Dev-Cpp\include\C++\3.4.2\*

" for SAP B1 
let $B1_APP='E:\project\3230\BUSMB_B1\SBO\2006A_COR\Application'
set path+=$B1_APP/*/Hdr,$B1_APP/Tools/Headers,$B1_APP/InfraStructure/SDK/Include
" set tag+=d:/bat/b1_tags

" }}}

" -------- �������ù���
nmap \1 :MyProjectsToggle<cr>

" �Զ�����vimprojects�ļ�
"nmap <silent> \` :Project E:\projects\prof_yao\EHR\EHR_asp\vimprojects<CR><CR>

" ����javascript��ʽ
"nmap \1 :syntax clear \| :ru! syntax/javascript.vim<cr> \| :echo "ok"<cr>

"}}}

" vim: set foldmethod=marker : cms="%s
