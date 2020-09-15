# Async Job Processing

A coding challenge solution.

## Problem

We've deployed a server that you can start jobs on. What do the jobs do? Doesn't really matter. What is important is that the jobs will always take ~0.5 seconds to complete. You can queue up a job like this:

```
$ curl -H "Content-Type: application/json" -d '{
  "account": "your email address",
  "wait": true
}' http://jobs.asgateway.com/start
```

Since `wait` is true, the server will just hang until the job is complete, at which time it will return this:

```
{
  "id":"4a40f6c1bf585ca9",
  "state":"completed",
  "startedAt":"2015-06-29T15:28:55.497Z",
  "proof":"E850075A4063332DE3D1C254E2A255424361DBDC"
}
```

We've provided a `jobclient` you can run on your local box against the job server:

```
$ jobclient --account 'example'
50 / 50 [=========================================================] 100.00 % 23s

Succeeded: 50
Average Duration: 11.368634862 seconds
Total Duration: 23.49453871 seconds

WORK SAMPLE RESULT: FAILED
```

Uh oh - the `jobclient` couldn't complete successfully. What's going on? Well, the `jobclient` runs 50 jobs, and all of those jobs need to both succeed, and they all need to complete within 5 seconds. If any jobs return an error, or it takes the `jobclient` more than 5 seconds to run **all** the jobs, it will fail.

Why can't it complete them in time? Well, it turns out our little job server can run a **lot** of jobs simultaneously. But what it can't do is handle a lot of connections simultaneously. Actually, it turns out it can only handle one connection at a time per account! All connection attempts after the first one will queue up, waiting for the precious single handler.

But the job server provides a way around this - go asynchronous with a callback! If you set `wait` to false, and pass a callback url, the job server will immediately return a response:

```
$ curl -H "Content-Type: application/json" -d '{
  "account": "example",
  "wait": false,
  "callback": "http://requestb.in/1573xwm1"
}' http://jobs.asgateway.com/start
```

Returns:

```
{
  "state":"running",
  "id":"4499a6e0c2ef4b98"
}
```

And then, later, it will POST to the callback url you supplied with a request like this:

```
POST http://requestb.in/1573xwm1
Content-Type: application/json
{
  "id":"4499a6e0c2ef4b98",
  "state":"completed",
  "startedAt":"2015-06-29T15:34:16.850Z",
  "proof":"078DC91F2980650231E94E67777078D5C926B9A3"
}
```

This sounds great, so what's the problem? Well, the `jobclient` which we've supplied and that verifies successful completion of the sample, *doesn't know how to interact with the asynchronous API*. It can open up a **lot** of connections, but since it always specifies `wait: true`, it'll quickly consume the available connection and spend all its time waiting for replies.

## Assignment

So your task is simple: write something that sits in-between the supplied client and the server, which lets the client hold open a *lot* of connections, and turns the synchronous client requests into asynchronous requests to the server. Note that you can pass a url into the `jobclient` to point it at your middleware:

```
$ jobclient --url http://jobs.asgateway.com/proxy --account example
50 / 50 [==========================================================] 100.00 % 1s

Succeeded: 50
Average Duration: 1.384823579 seconds
Total Duration: 1.636669279 seconds

WORK SAMPLE RESULT: PASSED

Proof (supply to Spreedly):
H4sIAAAJbogC/4RXOY4kyY69S8m/B0bSjEtrtp5gpGm04Ov9jzAvwhNfi0glqwoFPGfS3sZ...//+qbRsKqEQAA
```

Here are the constraints you should keep in mind when developing your async proxy:

* Because we need to be able to effectively assess your approach, please use one of these languages to build your proxy:
  * Ruby
  * Elixir
  * JavaScript
  * C#
  * Java
  * Python
* If these languages aren't in your wheelhouse, feel free to reach out to us to discuss if there's another language with which we are mutually familiar.  We aren't trying to assess your ability to pick up a new language.
* The app itself should run as a single *OS level* process. Running it within an app server is fine, but don't rely on the app server to provide the requisite concurrency (e.g., no use of app server threading, processes or other). The concurrency must be provided and managed by the app itself.
* It should process all jobclient requests in under 5 seconds
* We do not need to be able to run your code (the proof from the jobclient serves as evidence of successful functioning). So don't spend any time worrying about helping us set up the appropriate environment.
* Write your code like you would a prototype that could end up being deployed into production in the future: straightforward, lightweight, but with an eye to good coding practice that will allow it to be improved further.
* In addition to functioning code, please also write a test suite to accompany the application.

Ready to go? [We've built a little site for this sample, which has everything you should need - have at it!](http://jobs.asgateway.com/)


## Notes

Since this work sample does not need to be running somewhere accessible, you may find a tool like [ngrok](https://ngrok.com) useful to provide a public URL loopback to localhost.

# Description and analysis
 
 ## Project
 My work sample was written as a Phoenix project. Here are some details that may be useful.
 - There are two endpoints: `/proxy` and `/callback`.
 - Each endpoint has a controller.
 - There is a general business logic module.
 - There is a behaviour to define the functions of a response handler.
 - There is a `GenServer` module that implements the callbacks in that behaviour and manages state for the asynchronous request and response.
 - Tests were written for the business logic module and the response handler module. These modules have the vast majority of the interesting logic.
 - Tests were not written for the controllers because this was a time-boxed exercise. 
 - The Mox library is used for testing.
 - Among the other files, the configuration files are probably the most relevant for analysis because of how the configuration is used in the other modules.

## Start command used

The project is run as a Phoenix app. It is provided with a callback URL as an environment variable. The example here matches an ngrok.io URL that was used:

`CALLBACK_URL="http://0b32866f.ngrok.io/callback" iex -S mix phx.server`

## Accounting for errors from the job server
This implementation focuses on the happy path. There is very little explicit error handling.
 
 ## Updates to account for job server errors
I would say retrying when there are specific kinds of job server errors would be the most beneficial. I think there are two main error types that could be addressed with retries.

1. **Handle retries if the initial job request isn't started successfully.** If parameters for a job are valid but the initial attempt to start
a job is unsuccessful, retrying would be beneficial. This would require parameter validation and definition of a retry strategy.
2. **Handle retries if an initial job request starts successfully but isn't completed.** If the initial request to have a job started
succeeds but there is no subsequent completion of the job, retrying the full job may be beneficial. As with retrying the initial job request,
this would require defining a retry strategy. How we handle a started job that we dn't know is finished or not would depend on the rules laid down
by the contract between the job server and its clients. Questions to answer include:
  * Does the job server allow for querying to see the status of a job that we believe was started successfully?
  * What are the semantics of a complete retry? Are we in danger of having the job complete twice when we only want it to run once?
  * If a job runs twice, is that bad?
 
 ## Limitations of running on a single node
As I understand it, the process limits on an Erlang node are quite large. Erlang processes (which are what Elixir processes are) are lightweight. They use very little memory 
and switching between them is fast. That doesn't explain the limitations, though. I would hazard that the primary limitations on a single node will be 
physical: **the number of cores** that are available. In addition, the number of **incoming and outgoing connections** that can be held would be a limiting factor. 
 
 ## Changes to support running across several nodes
 This depends on the characteristics of the distributed system.
 
 ### Running multiple Erlang nodes in a trusted network
 In my implementation, the key to having an asynchronous job request successfully resolve is message passing across Erlang processes.
 If we are working in a system that is running on a trusted network, Erlang's capabilities for running across multiple nodes can allow for 
 message passing between processes across nodes in the same way that it allows for message passing between processes on the same node. As long
 as the nodes in the same system share the Erlang cookie, local and distributed processes are treated the same.
 
 ### Running in an untrusted network or across network boundaries
 If we cannot rely on Erlang's built-in ability to communicate across nodes, then some other form of message passing would be the most likely choice, perhaps 
 a **message queue**. For example, if I recall correctly, RabbitMQ allows for the creation of ephemeral queues. The process that starts the job
 could listen on an ephemeral queue for a message signalling that the job is complete. Another alternative would be a **shared data store** of some sort.
 The process that starts the job could poll the data store until it finds the data it needs. Polling seems like not nearly as good an alternative as
 a queue.
 
 ## Improvements that can be made
 There are plenty of opportunities for improvements. They include:
 * Handle errors if the initial request is invalid. As noted earlier, error handling is minimal. One very useful update would be
 to communicate back to the caller when an initial request is invalid. Some of those problems could be handled by validating
 the incoming data. Some others could be handled by dealing with errors that the job server returns.
 * Related to this would be an update to the `FallbackController`, the default Phoenix module that handles errors. 
 Because of time constraints, I did not update it beyond the basic 404 handling that Phoenix sets up.
 * Manage retries if a job doesn't start successfully or if it starts successfully but we receive no communication about its completion. This is
 covered in an earlier section.
 * Figure out what to do if the attempt to complete the response does not find an active process for that response. When my proxy receives
 the callback, it tries to find the process that is handling the request. What would it mean for the process
 handling the initial request not to be present? Was the request terminated? Was there some other condition that caused the GenServer
 to die?
 * The mechanism for waiting for a response is pretty straightforward. There may be less naive, perhaps even more robust, mechanisms.
 * The tests of the GenServer include a wait! This is a sign that there are improvements that could be made so that waiting is not required.
