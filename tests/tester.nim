import nim_todo_issue
import unittest

test "getOptions":
  block:
    let o = getOptions("owner/repo")
    check(o.token == "")
    check(o.keyword == "TODO")
    check(o.ownerAndRepo == "owner/repo")
    check(o.dirPath == ".")
    check(o.check == false)
  block:
    let o = getOptions("--token=xxx --keyword=KEY --check owner/repo dir_path")
    check(o.token == "xxx")
    check(o.keyword == "KEY")
    check(o.ownerAndRepo == "owner/repo")
    check(o.dirPath == "dir_path")
    check(o.check == true)


test "getAllGitHubIssues":
  discard getAllGitHubIssues("jinjor/nim-todo-issue")
  var raised = false
  try:
    discard getAllGitHubIssues("jinjor/no-repo-here")
  except IOError:
    raised = true
  check(raised)


test "searchIssues":
  check(searchIssues("TODO", "./tests/assets").len == 4)
  check(searchIssues("FIXME", "./tests/assets").len == 0)
  check(searchIssues("TODO", "./src").len == 0)


test "report":
  let
    gi1 = GitHubIssue(number: 1, isPullRequest: false, isOpen: true)
    gi2 = GitHubIssue(number: 2, isPullRequest: false, isOpen: false)
    i1 = Issue(number: 1, file: "", raw: "")
    i2 = Issue(number: 2, file: "", raw: "")
  check(report(@[], @[], true) == 0)
  check(report(@[], @[i1], true) == 0)
  check(report(@[gi1], @[i1], true) == 0)
  check(report(@[], @[i2], true) == 0)
  check(report(@[gi1], @[i2], true) == 0)
  check(report(@[gi1, gi2], @[i1], true) == 0)
  check(report(@[gi1, gi2], @[i2], true) == 1)
  check(report(@[gi1, gi2], @[i2], false) == 0)
