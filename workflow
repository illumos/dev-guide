# Basic illumos workflow

This section of the developer's guide introduces a basic workflow for developing
and working on the illumos code base. This workflow is intended and designed for
those who have never worked with illumos before, though have some basic
experience building programs written in the C programming language. It will take
you from obtaining a copy of the illumos source tree all the way through to
getting it ready for putback.


## Obtaining the source

illumos uses [git](http://git-scm.com/) for its source control management. The
simplest way to obtain the illumos source is to clone the git tree. You should
first make sure that git is installed. You can do this with the following
command:

```
$ which git
/usr/bin/git
```

The location of git may be different, but if it says git is not there, you
should consult your distribution's documentation for installing packages.

illumos can be built inside of a zone or in the global zone. It can also be
built as a user or as the super user. In most environments you will be doing
your work as a normal user. The rest of this guide will assume you are a normal
user. There should be no change if you are building as the super user.

The primary git repository is on
[github](http://github.com/illumos/illumos-gate) under the illumos organization.
To get started you should pick a file system location to do your work. Once
there, you can use git to obtain a copy of the source tree:

```
$ whoami
rm
$ cd /ws/rm
$ git clone git://github.com/illumos/illumos-gate.git
Cloning into illumos-gate...
remote: Counting objects: 331190, done.
remote: Compressing objects: 100% (73583/73583), done.
remote: Total 331190 (delta 238180), reused 322706 (delta 232512)
Receiving objects: 100% (331190/331190), 211.34 MiB | 1.32 MiB/s, done.
Resolving deltas: 100% (238180/238180), done.
$ cd illumos-gate
$ ls
README          exception_lists usr
```

Obtaining a copy of the illumos source tree may take several minutes depending
on the speed of your network connection. Feel free to place your workspace
wherever you want on the file system. The rest of this guide will assume it is
`/ws/rm/illumos-gate`. Once you've verified that you have it, we can prepare to
build the gate.


## Preparing to Build

While you may only want to work on a single component of illumos, the simplest
way to do that is to do a full build of the stock gate and then start making
your changes. This makes it so you don't have to worry as much about what your
component depends on.

You'll want to make sure that you have all the build dependencies necessary
already installed. Distributions have different ways of getting these packages.
Each distribution has their own way of getting this set up. You should consult
your illumos distribution on the best way to take care of getting this set up.

### Setting up illumos.sh

The easiest way to do the full build is to run nightly(1ONBLD). This takes care
of building everything that you might care about and in the right order.
`nightly` works off of a file that contains environment variables that describe
how and what to build. A set up and highly commented copy of this file already
exists for you to use. To get started we're going to copy the stock environment
variable, modify it ever so slightly, and then do the build.

```
$ cd /ws/rm/illumos-gate
$ cp /opt/onbld/env/illumos illumos.sh
$ vi illumos.sh
```

To get going there are a few important changes that you have to make this file,
specifically to tell `nightly` where your workspace is located. Following that,
we'll ensure that we're set up to use the correct compiler.

As you're looking at the environment file, you'll find that the first thing you
encounter is the `NIGHTLY_OPTIONS` variable. This controls what's get built by
`nightly`. Sticking with the default settings will build all of the different
components for illumos in a debug-only build. If you need something else, for
example a non-debug build for building a release or performance testing, please
see the nightly(1ONBLD) manual page.

#### Setting the path to our workspace

Next, we need to make sure that `nightly` and other tools can find where to find
our illumos workspace. The variables that we want to modify are `GATE` and
`CODEMGR_WS`. We're going to set `GATE` to the name of the directory that we're
in and `CODEMGR_WS` to the path to it. So in our case the lines in `illumos.sh`
will look like:

```
export GATE="illumos-gate"

...

export CODEMGR_WS=$(git rev-parse --show-toplevel)
```

#### Setting the Compiler

illumos uses [gcc](http://gcc.gnu.org/) as its primary compiler. gcc 7.3.0 is
the primary compiler right now and gcc 10.3.0 is the shadow compiler. Building
with both compilers is required. In addition, we leverage the tool smatch as
another shadow compiler for catching lint errors. The default illumos
environment file is configured to use gcc7 as the primary and 10 as the shadow.
You may need to tweak their paths.

### Obtaining Closed Binaries

While Sun made almost all of the operating system open source, there are still a
few closed components that the illumos community is replacing. You can obtain a
copy of these closed binaries from a mirror provided by Joyent. You'll want to
perform the following:

```
$ cd /ws/rm/illumos-gate
$ curl -O https://download.joyent.com/pub/build/illumos/on-closed-bins.i386.tar.bz2
$ curl -O https://download.joyent.com/pub/build/illumos/on-closed-bins-nd.i386.tar.bz2
$ tar xjvpf on-closed-bins.i386.tar.bz2
$ tar xjvpf on-closed-bins-nd.i386.tar.bz2
```

## Build illumos

Now we can go ahead and build illumos. I suggest that you do the build inside of
a screen session or nohup, making it easier to run your build unattended.

```
$ cd /ws/rm/illumos-gate
$ /opt/onbld/bin/nightly ./illumos.sh
$ echo $?
0
```

The amount of time that it takes `nightly` to complete varies. It can take
anywhere from forty minutes at the low end to several hours. The more CPUs
available to the build, the faster it will go.

## Diagnosing Build Failures

As you work on illumos, builds will fail. When a `nightly` completes it leaves
behind two different files that describe what happened inside of the build. The
first is the `nightly.log`. This file contains a record of all the commands that
were executed. If your build failed, it should contain the specifics of
everything that happened. The other file is the `mail_msg`. This summarizes the
different phases of the build, how long they took, and any warnings or noise
encountered. It should be clean.

If a build fails, the first stop is usually the `nightly.log`. Every run of
nightly leaves a log in its own directory based on the time stamp of the build.
A given `nightly.log` may contain multiple errors. `nightly` tries as hard as
possible to run to the end even if there is a build failure. Because of that,
it's important to make sure you find the first error. Errors usually have the
form: `*** Error code 1`. The following shows how to find the logs and errors
inside of them:

```
$ cd /ws/rm/illumos-gate
$ cd log
$ ls
log.2013-04-26.16:56  log.2013-05-01.17:02  log.2013-05-01.19:05
$ cd log.2013-05-01.19:05
$ ls
mail_msg         nightly.log      proto_list_i386
$ vi nightly.log
# Search for the first instance of the pattern \*\*\*
```

Note that if your build failed you will not generally see the file
`proto_list_i386`.


## Your Best Friend while Building: bldenv

bldenv(1ONBLD) is a tool designed to get you into a development environment for
doing incremental build work. Once you've done your first `nightly` it's the
only way to work. To get started, you use the same `nightly` environment file
that we previously set up. Let's go ahead and use `bldenv`:

```
$ cd /ws/rm/illumos-gate
$ /opt/onbld/bin/bldenv -d ./illumos.sh
Build type   is  DEBUG
RELEASE      is 
VERSION      is illumos-gate
RELEASE_DATE is May 2013

The top-level 'setup' target is available to build headers and tools.

Using /bin/bash as shell.
$
```

Because we had started with a debug build in `nightly`, we now use the `-d` flag
to `bldenv` to make sure that we continue in a debug build environment. If for
some reason we had done a normal build, we could omit the `-d` argument.


## Incremental Building

### cscope

Before we begin building, it's rather useful to build the `cscope` database.
`cscope` is a tool which allows you to easily search the source tree for
definitions, function call locations, symbol usage, variable assignment, and
more. It can speed up the process of what might normally be a find and recursive
grep quite substantially. `cscope` is built and provided as a part of the build
tools. While in bldenv, it will already be in your path as a program called
`cscope-fast`. From the root of the tree, you can create the database and use it
via:

```
$ cd usr/src
$ dmake cscope.out
$ cscope-fast -dq
```

Various editors have integration with `cscope` which makes keeping around a
cscope database quite useful and makes it easier to follow code paths across the
code base.

### The Proto Area and You

As different components are being built, they are delivered into what we call
the proto area. Everything that you're going to want to use and test gets
installed into the proto area before it gets packaged for updating a system.
Furthermore, as you build, components look to the proto area to find what they
need. For example, all of the header files like `<sys/types.h>` or `<stdio.h>`
are installed into the proto area. When you build a command that uses one of
those header files, it uses the copy from the proto area.

You might ask yourself, why do we have the proto area. The problem that the
proto area solves is that the system that you're building on might look rather
different from the one that it is going to end up on. If you're adding a new
interface to a library and updating a command to use that new interface, you
can't use the build system's copy of that header, as it wouldn't contain the new
function. The build system might not even have that header or library installed!

Furthermore, there are occasionally libraries and headers that are used to help
build the system, but are not actually shipped. For example, `libpcidb.so.1`
does not have a compilation symlink delivered to systems, but it does have one
in the proto area to allow commands like `prtconf(8)` to link against it.

### What do I Modify?

One of the first questions that you have to answer is what is it I have to
modify? Generally, you're working on a specific component of the kernel, some
library, command, or something which spans across all three of these boundaries.
Here are some questions to help guide you and help you figure out what exactly
you'll need to build.

* Am I modifying a public header file that comes with the system or a specific
  library as part of this work?

If you're changing a header file, you'll need to install the new copy into the
proto area before you rebuild a library, command, or kernel module which uses
it.

* Am I modifying a library to add new interfaces into it that something else
  needs?

Sometimes when you're working with a library, you're working on bug fixes and
enhancements that don't change the libraries API. However, if you're adding new
functionality to it, you'll need to build and install it into the proto area
before you can rebuild other libraries or commands that need it.

* I'm adding a new ioctl or another way for userland to talk to the kernel.

Here, there are multiple components that need to be modified. You need to first
install the header file that both the kernel and userland share and install that
into the proto area. Once that's done, it doesn't matter what order you modify
the userland and kernel components, as long as they all end up in the proto area
before you move onto testing.

### The Common Makefile Targets

Across most components there is a common set of three targets that are the most
common and most used.

* install

This will install the component into the proto area. It also ensures that the
build is up to date first. This is probably the target that you'll run the most.

* install_h

This is a special target for installing header files specifically. Generally
header files need to be installed before you can use the install.

* clobber

This removes all of the intermediate object files and the final components. This
is useful if you want to just do a fresh, non-incremental, build of a given
component.

### Building Individual Components

#### Userland Libraries and Commands

Building userland libraries and commands is pretty straightforward. All you have
to do is go into the directory of a command and run `dmake install`. This will
take care of building anything that's changed, link the resulting binary or
library, and install it into the proto area.

The common workflow here is to modify the source code and compile it via `dmake
install`. If you're warning and error free, then you'll see the new version be
installed into the proto area. However, often times you'll run into compiler
warnings and errors. This is the time and place to fix those, don't ignore
warnings! By default, `dmake` builds in parallel mode, so it will try to run
multiple jobs in parallel. If you're hitting errors and it's hard to understand,
instead, use `dmake -m serial install`. The `-m serial` instructs it to only
build one thing at a time.

Here's an example of building a command:

```
$ # We're sitting at what we consider the source tree root, inside usr/src.
$ cd cmd/dtrace
$ vi dtrace.c
$ dmake install
$ # The new copy will now be in the proto area.
$ cd ../..
$ cd lib/libctf/
$ vi common/ctf_subr.c
$ dmake install
$ # The new copy will now be in the proto area.
```

Most libraries and some commands have both 32-bit and 64-bit versions. If you
want to build just a specific version, you can cd into the architecture specific
directory. Note that not all commands have multiple versions, some only have a
single one. Say you wanted to build the 64-bit version of libumem. You would then
do:

```
$ cd lib/libumem/amd64/
$ dmake install
$
```

Unless you have a specific need, you should just stick with the top level one
that takes care of all the architectures.

#### Header Files

For header files, you'll want to run `dmake install_h` in the appropriate
directory. For libraries, this is in the root of that library. For the kernel,
the easiest way to do this is at the root of the `uts` directory. In action,
this looks like:

```
$ cd lib/libkstat
$ vi kstat.h
$ dmake install_h
$
```

```
$ cd uts
$ vi common/sys/mac_client.h
$ vi intel/sys/cpu.h
$ dmake install_h
$
```

#### Kernel Components

Unlike libraries and commands, the build information for these components is
kept in a different directory from the source. The majority of the kernel is in
`uts/common/`, while the minority is in architecture and platform specific
directories. Take for example, the driver igb(4D). The source for it lives
in `uts/common/io/igb/`. However, to build it you need to be in the architecture
specific directory, either `intel` or `sparc` currently. Once in there, you can
go ahead and use the same `dmake install` techniques that we've been using
elsewhere.

```
$ vi uts/common/io/igb/igb_mac.c
$ cd uts/intel/igb
$ dmake install
$
```

#### When in Doubt

If you find yourself in doubt as to what you should be doing or you're worried
about the dependency chain, you can always just run nightly again or run `dmake
install` from a higher top level directory. For example, running `dmake install`
from inside of `lib/` will make sure that every library is up to date. If you're
having trouble knowing how to build a specific component, you can look at the
Makefile in its directory, trudge through the `nightly` log file, or [ask
around](./help.html).

## Testing

While writing the code is important, making sure that it is correct is even more
important. Answering the question of what testing is necessary is hard. It
depends on the component and the nature of the change. Some components have unit
test in the tree already such as  `zfs`, `mdb`, and `dtrace`, while others do
not.

Testing should be shrink to fit. The question to ask yourself, is what testing
do you need to convince not only yourself, but someone else - such as your code
reviewers or integration advocate - that your change is correct. The rest of
this section will cover strategies for using your new versions of the software,
often referred to as 'using new bits'. Which strategies you can use depends on
the nature of the changes that you've made.

Keep track of your testing. While you may not integrate your tests along side
your changes, you'll need to note how you tested when you integrate your
changes. Providing and making those tests available if appropriate, is always
preferred.

### Install and Boot into the new system

One of the easiest ways to test your changes is to boot a test system onto your
new bits. No matter what kind of change you've made, this should work. There are
various ways to do this based on your distribution; however, for most folks this
can be achieved via the build tool onu(1ONBLD). If you're inside of bldenv and
have finished your build, the simplest way to do this is:

```
# onu -t new-nightly-be
#
```

Once this is done, you can reboot into the new build environment. You'll want to
consult with your distribution for the best way to do this.

Once you have your bits installed, you can run any tests you want against a host
machine.

### Testing from the proto area

Sometimes one chooses to test something straight from the build machine itself.
For example, if you've modified `head(1)` or `grep(1)`, that might be alright.
However, this can be dangerous and lead you to wasting your time. Recall are
comments on why we use the proto area, well, now all of those can happen, but
flipped around.

If you have just modified a binary, then you may be able to use that directly
from the proto area:

```
$ cd /ws/rm/illumos-gate/proto/root.i386-debug/root/usr/bin
$ ./head /var/tmp/foo
$
```

If you have modified a library and want to test a command against it, you can
take advantage of the `LD_LIBRARY_PATH`, `LD_LIBRARY_PATH_32`,
`LD_LIBRARY_PATH_64`, `LD_PRELOAD_32`, `LD_PRELOAD_64`, and `LD_PRELOAD`
environment variables to make sure that you use the new version of the library.
For the full usage of these, see the `ENVIRONMENT VARIABLES` section of
ld.so.1(1). You have to exercise caution when using these. Your
`libc.so.1` and kernel must always match! If they don't, a lot can manage to go
wrong and be very hard to debug. It is always safest to just boot your new bits!

### Binary verification between proto areas

Depending on the nature of your change, it can be useful to understand the
differences between binaries that your changes introduced. Checking the
differences of the produced binaries between changes can verify that you changed
what you intended to. For example, let's say that you have removed what you
believe is unused code from a subsystem.  If the code was indeed unused, then
the binary should be almost identical to the binary from the previous build.
Another use is to verify that your change did not unintentionally affect
another part of the codebase.

illumos provides a tool that can verify this automatically:
[`wsdiff(1ONBLD)`](http://illumos.org/man/1onbld/wsdiff). To run `wsdiff`,
specify `-w` in your `NIGHTLY_OPTIONS`. For `wsdiff` to work, it needs to be run
between two consecutive builds. Therefore, the common workflow is to first build
the gate with `nightly`, make your changes, and then run `nightly` again, but
this time with `wsdiff` enabled.

`wsdiff` isn't perfect. There are a few things can cause noise to show up in its
output. For example, the illumos `DEBUG` builds often carry macros like
`__LINE__` that emit line numbers and DTrace probes will often have a part of
the DOF section change which encodes information about how it ws generated. As a
result, it is expected that some differences that have to do with changes in the
actual source files will pop up in such builds. You may find that `wsdiff` is
easier to use with `non-DEBUG` builds.

## Committing your Work

As you make progress, you should feel free to make incremental commits in your
local repository. This is one of the great advantages of the bring over, modify,
merge strategy: you can make your own local commits and then later on rewrite
that history. You should make commits whenever you feel like it. Think of them
as a way to track your own progress and provide snapshots that you can roll back
to in case anything goes awry. You can commit groups of files or the entire
tree. The following examples explore how to do this with `git`:

```
$ # Commit only a select few files
$ git commit cmd/mdb/common/mdb/mdb_typedef.c
$ # Commit all changes
$ git commit -a
$
```

If you've added files, you'll want to make sure that you've added them to the
git repository. Say you wrote the library `librm`. Assuming that you don't have
any build files present, you should could run the following:

```
$ git add -n lib/librm
$ # Check the above dry run and verify it has everything you expect
$ git add lib/librm
$ git commit -a
$
```

If you make commits that are in awkward places in time or have a slightly
incorrect message, don't worry. Before you integrate you'll squash all of these
changes down into one commit and have the chance to fix that up.

## From Build to Integration

You've built your changes, made some local commits, and tested them. The hard
part is done! Before you can get the change integrated there are a few steps
that need to be done. These steps insure that the gate has consistent style and
catches a common errors.

### Lint and make check

In addition to compiler warnings, illumos-gate uses a tool called `lint` which
checks for various programming errors. Historically, compilers did not always
issue warnings about various constructs and issues which led to programmer
error. Because of that, the tool `lint` was adapted from the `pcc` compiler.
Today, the `lint` that illumos-gate uses comes from the Sun Studio Compiler
Collection.

In addition to the `lint` checks, there is a Makefile target called `make check`
that validates aspects of header files and style.

The easiest way to do check all of this is to simply run `nightly` again and
look at the contents of the `mail_msg`. If you see errors from there, you will
need to go back and make the appropriate fixes.

### webrev

There are lots of ways that you can share your changes with other people. The
preferred format by the illumos community is that of the webrev(1ONBLD). A
`webrev` is a series of html pages that show the differences and changes in your
code. `webrev` allows people to select various kinds of `diff` formats to use to
look and review your changes. Unlike looking simply at a `diff` or `patch` file,
a `webrev` breaks down the changes on a per-file basis and allows for the reader
to get much more context than normally is possible.

Creating a webrev is easy. All you need to do is make sure that you have your
changes committed locally. It doesn't matter how many commits you have. By
default, all of your uncommitted changes are compared to the head of the tree.
The `webrev` tool has many options for comparing your changes against different
revisions. See the `OPTIONS` section of webrev(1ONBLD) if you need something
other than the default. Otherwise, you can generate a webrev simply by doing the
following while in `bldenv`.

```
$ webrev
$ find /ws/rm/illumos-gate/webrev
$
```

You'll want to share your webrev with your reviewers. If you don't have a place
to upload it or share with them, the illumos community provides some common
places for that which is `cr.illumos.org`. See XXX for more information on
using `cr.illumos.org`.

### Reviewers

As part of your work, you'll want to find reviewers for your change. The best
reviewers are those who have expertise in the area that you care about. In
several cases the original authors of various parts of the system are in the
illumos community. So if you were working on ZFS, you'd want to make sure that
the core ZFS folks take a look at it by sending a review request to the ZFS
mailing list. Much like testing, review scales to fit. The more complex the
change, the more important that someone who is familiar with the subsystem and
its inner workings reviews it. A longer discussion of code review is in the
[Integrating Changes](./integrating.html) section.

### Squashing Commits and Commit Messages

illumos has a standard commit format. That is:

```
<bug id> <synopsis>
<bug id 2> <synopsis 2>
<Reviewer n>
<Reviewer n+1>...
<Advocate>
```

An example of this is:

```
3673 core dumping is abysmally slow
3671 left behind enemy lines, agent LWP can go rogue
3670 add visibility into agent LWP's spymaster
Reviewed by: Keith M Wesolowski <keith.wesolowski@joyent.com>
Reviewed by: Joshua M. Clulow <jmc@joyent.com>
Reviewed by: Robert Mustacchi <rm@joyent.com>
Reviewed by: Richard Lowe <richlowe@richlowe.net>
Reviewed by: Garrett D'Amore <garrett@damore.org>
Reviewed by: Eric Schrock <eric.schrock@delphix.com>
Approved by: Richard Lowe <richlowe@richlowe.net>
```

In a given change, there may be one or more bugs fixed. Each bug corresponds to
an entry at <http://illumos.org/issues/>. If you have logically separate
changes, they should be done as separate commits. A rule of thumb is that if a
single bug fix or RFE can stand on its own, it probably should. You should
mention Reviewers in the commit message and don't worry about the 'Approved By'
line, the advocate will take care of that for you.

In addition to the commit format, a given change should only be one commit. If
you already have one commit, you can modify the message by using the following
`git` command:

```
$ git commit --amend
$
```

If you have multiple commits, you should use `git rebase` to squash them down
into just one commit. As a part of a rebase, you will have the option to change
the commit message. To do this, you should run:

```
$ git rebase -i origin
$
```

Once you have, your tested change and your reviewers in line, there's just one
last stop.

### pbchk

The last step is to run `git pbchk`. `git pbchk` runs several tests on the
source base including checking the commit message, style, copyright checks and a
few others. To see the full list see
[`git-pbchk(1ONBLD)`](http://illumos.org/man/1onbld/git-pbchk). With one
exception, copyright, you should fix all of the issues listed. Whether or not
you choose to put a copyright message for your modified code is up to you (and
whomever actually owns the copyright).

## Victory

Congratulations! The changes that you've been working on should now be good to
go. There is a lot to still explore and understand. Consider taking some time
and reading it through or just going to a specific area based on your interest.

Specific places to go include:

- [Integrating Changes](./integrating.html)

- [Component Anatomy, Creating and Modifying Components](./anatomy.html)

- [Debugging](./debugging.html)

- [Getting Help](./help.html)
