
    --
    -- Basic Streams: Strings, Files, Pipes and Sockets
    --
    -- Copyright (c) 2011-2012 iNTERFACEWARE Inc.
    --

    -- How much data to buffer between reads.
    local buffer_size = 64*1024

    -- Throw errors reported by io.open().
    local function open(path, mode)
       local file, err = io.open(path, mode)
       if not file then
          error(err, 3)
       end
       return file
    end

    -- Throw errors reported by io.popen().
    local function popen(cmd, mode)
       local file, err = io.popen(cmd, mode)
       if not file then
          error(err, 3)
       end
       return file
    end

    -- Stream from some open file (see fromFile, fromPipe).
    local function fromFile(file)
       return function()
          local out
          if file then
             out = file:read(buffer_size)
             if not out then
                file:close()
                file = nil
             end
          end
          return out
       end
    end

    -- Stream to some open file (see toFile, toPipe).
    local function toFile(file, from, ...)
       local chunk
       repeat
          chunk = from(...)
          if chunk then
             file:write(chunk)
          end
       until not chunk
       file:close()
    end

    --
    -- Public API
    --

    stream = {}

    -- stream.fromString(s)
    --
    -- Create a stream from a string.
    --   's' - the string
    --
    -- e.g. stream.toFile('out.txt', stream.fromString(Data))
    --
    function stream.fromString(s)
       return function()
          local out
          if #s > 0 then
             out = s:sub(1,buffer_size)
             s = s:sub(buffer_size+1)
          end
          return out
       end
    end

    -- stream.toString(from, ...)
    --
    -- Write a stream to a string.
    --   'from(...)' - the stream to read from
    --
    -- e.g. local s = stream.toString(stream.fromFile('in.txt'))
    --
    function stream.toString(from, ...)
       local out, chunk = {}, nil
       repeat
          chunk = from(...)
          if chunk then
             out[#out+1] = chunk
          end
       until not chunk
       return table.concat(out)
    end

    -- stream.fromFile(path [,mode])
    --
    -- Create a stream from a file.
    --   'path' - the path of the file
    --   'mode' - the mode to use (defaults to 'rb')
    --
    -- e.g. local s = stream.toString(stream.fromFile('in.txt'))
    --
    function stream.fromFile(path, mode)
       local file = open(path, mode or 'rb')
       return fromFile(file)
    end

    -- stream.toFile(path, from, ...)
    -- stream.toFile(path, mode, from, ...)
    --
    -- Write a stream to a file.
    --   'path'      - the path of the file
    --   'mode'      - the mode to use (defaults to 'wb')
    --   'from(...)' - the stream to read from
    --
    -- e.g. stream.toFile('out.txt', stream.fromString(Data))
    --
    function stream.toFile(path, mode, from, ...)
       if type(mode) == 'function' then
          return stream.toFile(path, 'wb', mode, from, ...)
       end
       local file = open(path, mode)
       return toFile(file, from, ...)
    end

    -- stream.fromPipe(cmd)
    --
    -- Create a stream from an external process.
    --   'cmd' - the command to run and read from
    --
    -- e.g. local s = stream.toString(stream.fromPipe('ls -1'))
    --
    function stream.fromPipe(cmd)
       local file = popen(cmd, 'r')
       return fromFile(file)
    end

    -- stream.toPipe(cmd, from, ...)
    --
    -- Write a stream to an external process.
    --   'cmd'       - the command to run and write to
    --   'from(...)' - the stream to read from
    --
    -- e.g. stream.toPipe('openssl des -out out.tmp -k '..Key,
    --                    stream.fromString(Data))
    --
    function stream.toPipe(cmd, from, ...)
       local file = popen(cmd, 'w')
       return toFile(file, from, ...)
    end

    -- stream.fromSocket(sock)
    --
    -- Create a stream from a TCP/IP connection.
    --   'sock' - the connection to read from
    --
    -- e.g. local s = net.tcp.connect{...}
    --      stream.toFile('big.hl7', stream.fromSocket(s))
    --
    function stream.fromSocket(sock)
       return function()
          return sock:recv()
       end
    end

    -- stream.toSocket(sock, from, ...)
    --
    -- Write a stream to a TCP/IP connection.
    --   'sock'      - the connection to write to
    --   'from(...)' - the stream to read from
    --
    -- e.g. local s = net.tcp.connect{...}
    --      stream.toSocket(s, stream.fromFile('big.hl7'))
    --
    function stream.toSocket(sock, from, ...)
       while true do
          local chunk = from(...)
          if not chunk then break end
          sock:send(chunk)
       end
    end

    -- stream.filter(from, f)
    --
    -- Create a stream by attaching a filter to another stream.
    --   'from' - the stream to read from
    --   'f'    - the filter function
    --
    -- The filter (f) is called with each chunk (or nil) read
    -- from the stream (from) and must return chunks (or nil)
    -- to be sent downstream.
    --
    -- e.g. local Out = stream.toString(
    --         stream.filter(stream.fromString(Data),
    --             function(s)
    --                return s and s:upper()
    --             end))
    --      assert(Out == Data:upper())
    --
    function stream.filter(from, f)
       return function(...)
          local out = from(...)
          return f(out, ...)
       end
    end

    return stream
