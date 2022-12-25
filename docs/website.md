<h1>Setting up a Server</h1>

**Installing Server**
```sh
wget run https://raw.githubusercontent.com/icanthink42/mc_internet/main/installs/server.lua
```

**Server Config**<br>
There are two config files for a server that will be created automatically when the server is installed:
 * `~/server/config.lua`
    - Allows you to specify where your web pages will be stored.
 * `~/utils/config.lua`
    - Allows you to switch debug mode on and off. (See more in utils.md)



**Making a Web Page**<br>
In the directory specified in the servers config there should be two folders:
 * `[PATH]/read`
    - Pages in here are send to and ran on the client
 * `[PATH]/run`
    - Pages here are run on the server and generate a page that is sent to the client
<br>
Note: `[PATH]` is the path specified in `~/server/config.lua`
<br>

Example of a `run` file:
```lua
o = {}

function o.run(ctx)
  -- Code here
  return code_for_client
end

return o
```

The run function should return lua to be run on the client.<br>
This allows a lot more interaction between the server and client.<br><br>
`ctx` defines info from the client and contains the following:<br>
 * `ctx.data.page`
    - The page requested by the client (str)
 * `ctx.data.run`
    - Whether the client requested code to be run on the server or not (bool)
 * `ctx.return_port`
    - The port the request should return on (str)
 * `ctx.protocol`
    - The request protocol. This should always be "Get" at this point. (str)

**Testing your Server**<br>
You are able to get your computers IP by running:
```id```
<br>
It may help to turn on debug mode in `~/utils/config.lua`<br>
<br>
You can run the server by running the file `~/server/main.lua`
