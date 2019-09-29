# nim_todo_issue

Search TODOs related to closed issues.

## Build

```
nimble build -d:ssl
```

## Run

```
./nim_todo_issue [--keyword=TODO] [--check] [--token=xxxxx] owner/repo [src_dir]
```

## Example

```
$ nimble build && ./nim_todo_issue jinjor/typed-parser tests/assets
  Verifying dependencies for nim_todo_issue@0.1.0
   Building nim_todo_issue/nim_todo_issue using c backend
Fetched 3 issues from GitHub.
📝 #1 [PR]        [OPEN]   tests/assets/foo.ts:  // TODO: #1 #2 implement something
📝 #2 [ISSUE]     [OPEN]   tests/assets/foo.ts:  // TODO: #1 #2 implement something
❗️ #3 [PR]        [CLOSED] tests/assets/bar.ts:  // TODO: #3 fix foo
❔ #4 [NOT FOUND]          tests/assets/bar.ts:  // TODO: #4 bla bla bla...
```
