0 ccall: h-open-com        { i.port# -- i.handle }
1 ccall: h-close-handle    { i.handle -- }
2 ccall: h-write-file      { a.buf i.len i.handle -- i.actual }
3 ccall: h-read-file       { a.buf i.len i.handle -- i.actual }
4 ccall: h-open-file       { $.name -- i.handle }
5 ccall: h-timed-read      { a.buf i.len i.ms i.handle -- i.actual }
6 ccall: ms                { i.ms -- }

" app.dic" save
