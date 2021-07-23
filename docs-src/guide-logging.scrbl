#lang scribble/manual
@(require "lib.rkt")

@title[#:version reach-vers #:tag "guide-logging"]{How do I add tracing logs to my Reach program?}

Sometimes it is useful to add "tracing logs" to your program so you can see the values of variables and computations as the program is running.
For example, if we were writing purely in JavaScript, we might write
@js{
  function fib(n) {
    console.log(`Starting to compute Fibonacci`);
    let i = 1;
    let [a, b] = [0, 1];
    while ( i++ < n ) {
      console.log(i, a, b);
      [a, b] = [b, a + b];
    }
    return a;
  }
  fib(9);
}
And we'd see the output
@verbatim{
Starting to compute Fibonacci
2 0 1
3 1 1
4 1 2
5 2 3
6 3 5
7 5 8
8 8 13
9 13 21
}

How can we do something like this in Reach?

The key is to use @tech{participant interact interfaces} to share arbitrary
information with the @tech{frontend}, which has the ability to log to a
console or any other tracing service.
For example:
@reach{
export const main = Reach.App(() => {
  const A = Participant('Alice', {
    logBool: Fun([UBool], Null),
    logNumber: Fun([UInt], Null),
  });
  deploy();
  A.only(() => {
    interact.logBool(true);
    interact.logNumber(1); });
  exit();
});
}

However, as this example shows, it can be inconvenient to use this pattern, because @reachin{Fun} types constrain their domains to particular input data types, but we may need to log different kinds of data at different points in the program.
Similarly, it is inconvenient to use an entire @reachin{only} block for a simple log.

Reach provides two conveniences for this situation that taste great together: @tech{unconstrained domain function types} and @tech{interact shorthand}.
The first allows a function in a @tech{participant interact interface} to have a completely unconstrained domain.
The second allows a call to a @tech{frontend} from anywhere without an @reachin{only}, provided the function returns no value.
If we re-write the above example using both of these patterns, it looks like:
@reach{
export const main = Reach.App(() => {
  const A = Participant('Alice', {
    log: Fun(true, Null),
  });
  deploy();
  A.interact.log(true);
  A.interact.log(1);
  // We can easily add more complex log entries as well.
  A.interact.log([1, true]);
  A.interact.log({x: 1, y: true});
  const x = 1;
  const y = true;
  A.interact.log({x, y});
  A.interact.log(Maybe(UInt).Some(5));
  exit();
});
}

Then, a JavaScript frontend can simply use @jsin{console.log} as the value of the @litchar{log} function.

Reach provides @reachin{hasConsoleLogger} and @tech{hasConsoleLogger (Frontend)} in the standard library
for default implementations of logging to stdout. It can be used in Reach with:

@reach{
const A = Participant('Alice', { ...hasConsoleLogger })
}

and in the JavaScript frontend with:

@js{
 backend.Alice(
    ctcAlice,
    { ...stdlib.hasConsoleLogger },
  ),
}

The Reach development repository contains an example of this pattern: @reachexlink["log/index.rsh"] and @reachexlink["log/index.mjs"].
